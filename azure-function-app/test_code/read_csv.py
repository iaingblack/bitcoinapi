import pandas as pd
import time


start_time = time.time()

# Path to the ZIP file
file_path = "../data/btcusd_1-day_data.csv"

# Read the CSV file directly from the ZIP
with open(file_path) as f:
    df = pd.read_csv(f)

print(df.head())

end_time = time.time()

execution_time = end_time - start_time
print(f"Script executed in {execution_time:.4f} seconds.")