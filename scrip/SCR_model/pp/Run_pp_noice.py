import os
from glob import glob
import pandas as pd
from Function_pp_noice import process_noise_info

output_dir = r""
os.makedirs(output_dir, exist_ok=True)

input_files = glob(r"\*.csv")  


for file_path in input_files:
    print(f"processing：{file_path}")
    _, noise_df = process_noise_info(file_path)
    subject_id = os.path.splitext(os.path.basename(file_path))[0]
    output_file = os.path.join(output_dir, f"{subject_id}.csv")
    noise_df.to_csv(output_file, index=False)
    print(f"save：{output_file}")