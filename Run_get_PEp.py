import os
from glob import glob
import pandas as pd
from Function_get_PEp import process_noise_info

# 创建保存输出的文件夹
output_dir = r"D:\paper2\up_data code and data\PEp_event"
os.makedirs(output_dir, exist_ok=True)

# 获取所有被试的 csv 文件路径（你可以修改成你的目录）
input_files = glob(r"D:\paper2\up_data code and data\MIST_data\*.csv")  # 例如你将文件都放在 data 文件夹里


for file_path in input_files:
    print(f"正在处理：{file_path}")
    down_noise_df = process_noise_info(file_path)
    subject_id = os.path.splitext(os.path.basename(file_path))[0]
    output_file = os.path.join(output_dir, f"{subject_id}_PEp.csv")
    down_noise_df.to_csv(output_file, index=False)
    print(f"已保存到：{output_file}")