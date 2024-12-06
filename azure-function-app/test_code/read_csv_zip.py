import pandas as pd
from zipfile import ZipFile
import time
from azure.storage.blob import BlobServiceClient

start_time = time.time()

# Path to the ZIP file
zip_file_path = "../data/btcusd_1-day_data.csv.zip"

# Read the CSV file directly from the ZIP
with ZipFile(zip_file_path) as z:
    with z.open("btcusd_1-day_data.csv") as f:  # Replace 'file.csv' with the name of the CSV inside the ZIP
        df = pd.read_csv(f)

print(df.head())

end_time = time.time()

execution_time = end_time - start_time
print(f"Script executed in {execution_time:.4f} seconds.")