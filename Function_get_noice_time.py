import pandas as pd
import os
from glob import glob

def process_PEn_info(file_path):
    df = pd.read_csv(file_path)
    df = df.iloc[1:]  # 剔除第一个试次

    # 判断是否未作答
    df["no_response"] = df["trials.key_resp.keys"].isna()

    # 判断是否错误作答（反应延迟 > 1.5）
    df["wrong_response"] = (
        ~df["no_response"] &
        (df["trial.stopped"] - (df["textbox1.started"] + df["trials.key_resp.rt"]) > 1.5)
    )

    # 标记有噪音
    df["has_PEn"] = df["no_response"] | df["wrong_response"]

    # 初始化
    df["PEn_start"] = None
    df["PEn_duration"] = None

    df.loc[df["no_response"], "PEn_start"] = df["trial.started"]
    df.loc[df["no_response"], "PEn_duration"] = df["trial.stopped"] - df["trial.started"]

    df.loc[df["wrong_response"], "PEn_start"] = df["textbox1.started"] + df["trials.key_resp.rt"]
    df.loc[df["wrong_response"], "PEn_duration"] = df["trial.stopped"] - df["PEn_start"]

    # 提取噪音信息
    PEn_df = df[df["has_PEn"]][["trial.started", "trial.stopped", "PEn_start", "PEn_duration"]]
    # 删除最后一个试次如果 PEn_start > 300
    if not PEn_df.empty and PEn_df.iloc[-1]["PEn_start"] > 300:
        PEn_df = PEn_df.iloc[:-1]
        
    total_PEn_time = PEn_df["PEn_duration"].sum()

    return total_PEn_time, PEn_df

