import pandas as pd
import os
from glob import glob

def process_noise_info(file_path):
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
    df["has_noise"] = df["no_response"] | df["wrong_response"]

    # 初始化
    df["noise_start"] = None
    df["noise_duration"] = None

    df.loc[df["no_response"], "noise_start"] = df["trial.started"]
    df.loc[df["no_response"], "noise_duration"] = df["trial.stopped"] - df["trial.started"]

    df.loc[df["wrong_response"], "noise_start"] = df["textbox1.started"] + df["trials.key_resp.rt"]
    df.loc[df["wrong_response"], "noise_duration"] = df["trial.stopped"] - df["noise_start"]

    # 提取：有噪音 & 按键为 'down' 的试次
    down_noise_df = df[
        (df["has_noise"]) & (df["trials.key_resp.keys"] == "down")
        ][["trial.started", "trial.stopped", "noise_start", "noise_duration"]]
    # 删除最后一个试次如果 noise_start > 300
    if not down_noise_df.empty and down_noise_df.iloc[-1]["noise_start"] > 300:
        down_noise_df = down_noise_df.iloc[:-1]
        

    return  down_noise_df

