import pandas as pd
import numpy as np

def process_PEp_info(file_path):
    df = pd.read_csv(file_path)
    df = df.iloc[1:]  # Remove the first trial

    # Identify trials without a response
    df["no_response"] = df["trials.key_resp.keys"].isna()

    # Identify incorrect responses (reaction delay > 1.5 seconds)
    df["wrong_response"] = (
        ~df["no_response"] &
        (df["trial.stopped"] - (df["textbox1.started"] + df["trials.key_resp.rt"]) > 1.5)
    )

    # Mark trials that contain noise (either missing or incorrect responses)
    df["has_noise"] = df["no_response"] | df["wrong_response"]

    # Initialize columns for noise onset and duration
    df["noise_start"] = np.nan
    df["noise_duration"] = np.nan

    # Calculate noise onset and duration for missing responses
    df.loc[df["no_response"], "noise_start"] = df["trial.started"]
    df.loc[df["no_response"], "noise_duration"] = df["trial.stopped"] - df["trial.started"]

    # Calculate noise onset and duration for incorrect responses
    df.loc[df["wrong_response"], "noise_start"] = df["textbox1.started"] + df["trials.key_resp.rt"]
    df.loc[df["wrong_response"], "noise_duration"] = df["trial.stopped"] - df["noise_start"]

    # Extract noise event information
    noise_df = df[df["has_noise"]][["trial.started", "trial.stopped", "noise_start", "noise_duration"]]

    # Remove the last trial if noise_start > 300 (considered invalid)
    if not noise_df.empty and noise_df.iloc[-1]["noise_start"] > 300:
        noise_df = noise_df.iloc[:-1]

    # Calculate total noise duration
    total_noise_time = noise_df["noise_duration"].sum()

    # Extract valid correct-response trials (response present and reaction time <= 1.5s)
    correct_df = df[
        (~df["no_response"]) & (~df["wrong_response"])
    ][["trial.started", "trial.stopped", "textbox1.started", "trials.key_resp.rt"]]

    return correct_df
