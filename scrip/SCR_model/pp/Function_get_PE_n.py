import pandas as pd
import os
from glob import glob

def process_PEn_info(file_path):
    df = pd.read_csv(file_path)
    df = df.iloc[1:]  # Remove the first trial

    # Identify trials without a response
    df["no_response"] = df["trials.key_resp.keys"].isna()

    # Identify incorrect responses (reaction delay > 1.5 seconds)
    df["wrong_response"] = (
        ~df["no_response"] &
        (df["trial.stopped"] - (df["textbox1.started"] + df["trials.key_resp.rt"]) > 1.5)
    )

    # Mark trials that contain PEn (either missing or incorrect responses)
    df["has_PEn"] = df["no_response"] | df["wrong_response"]

    # Initialize columns for PEn onset and duration
    df["PEn_start"] = None
    df["PEn_duration"] = None

    # Calculate PEn onset and duration for missing responses
    df.loc[df["no_response"], "PEn_start"] = df["trial.started"]
    df.loc[df["no_response"], "PEn_duration"] = df["trial.stopped"] - df["trial.started"]

    # Calculate PEn onset and duration for incorrect responses
    df.loc[df["wrong_response"], "PEn_start"] = df["textbox1.started"] + df["trials.key_resp.rt"]
    df.loc[df["wrong_response"], "PEn_duration"] = df["trial.stopped"] - df["PEn_start"]

    # Extract PEn information
    PEn_df = df[df["has_PEn"]][["trial.started", "trial.stopped", "PEn_start", "PEn_duration"]]

    # Remove the last trial if PEn_start > 300 (considered invalid)
    if not PEn_df.empty and PEn_df.iloc[-1]["PEn_start"] > 300:
        PEn_df = PEn_df.iloc[:-1]
        
    total_PEn_time = PEn_df["PEn_duration"].sum()

    return total_PEn_time, PEn_df
