import pandas as pd
import numpy as np

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

    # 初始化噪音相关列
    df["noise_start"] = np.nan
    df["noise_duration"] = np.nan

    df.loc[df["no_response"], "noise_start"] = df["trial.started"]
    df.loc[df["no_response"], "noise_duration"] = df["trial.stopped"] - df["trial.started"]

    df.loc[df["wrong_response"], "noise_start"] = df["textbox1.started"] + df["trials.key_resp.rt"]
    df.loc[df["wrong_response"], "noise_duration"] = df["trial.stopped"] - df["noise_start"]

    # 提取噪音信息
    noise_df = df[df["has_noise"]][["trial.started", "trial.stopped", "noise_start", "noise_duration"]]

    # 删除最后一个试次（若其噪音开始时间大于300）
    if not noise_df.empty and noise_df.iloc[-1]["noise_start"] > 300:
        noise_df = noise_df.iloc[:-1]

    # 计算噪音总时长
    total_noise_time = noise_df["noise_duration"].sum()

    # 提取正确作答试次（非未作答 且 反应延迟 ≤ 1.5）
    correct_df = df[
        (~df["no_response"]) & (~df["wrong_response"])
    ][["trial.started", "trial.stopped", "textbox1.started", "trials.key_resp.rt"]]

    return correct_df
