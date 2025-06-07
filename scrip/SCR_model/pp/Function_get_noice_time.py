import pandas as pd
import os
from glob import glob

def process_noise_info(file_path):
    df = pd.read_csv(file_path)
    df = df.iloc[1:]  # Exclude the first trial

    # Determine missing responses
    df["no_response"] = df["trials.key_resp.keys"].isna()

    # Determine incorrect responses (reaction time delay > 1.5 seconds)
    df["wrong_response"] = (
        ~df["no_response"] &
        (df["trial.stopped"] - (df["textbox1.started"] + df["trials.key_resp.rt"]) > 1.5)
    )

    # Mark trials containing noise (either no response or incorrect response)
    df["has_noise"] = df["no_response"] | df["wrong_response"]

    # Initialize columns for noise onset and duration
    df["noise_start"] = None
    df["noise_duration"] = None

    df.loc[df["no_response"], "noise_start"] = df["trial.started"]
    df.loc[df["no_response"], "noise_duration"] = df["trial.stopped"] - df["trial.started"]

    df.loc[df["wrong_response"], "noise_start"] = df["textbox1.started"] + df["trials.key_resp.rt"]
    df.loc[df["wrong_response"], "noise_duration"] = df["trial.stopped"] - df["noise_start"]

    # Extract noise event information
    noise_df = df[df["has_noise"]][["trial.started", "trial.stopped", "noise_start", "noise_duration"]]

    # Remove the last trial if noise_start > 300
    if not noise_df.empty and noise_df.iloc[-1]["noise_start"] > 300:
        noise_df = noise_df.iloc[:-1]
        
    total_noise_time = noise_df["noise_duration"].sum()

    return total_noise_time, noise_df
