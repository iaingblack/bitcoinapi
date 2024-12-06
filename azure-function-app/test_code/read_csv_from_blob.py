from azure.storage.blob import BlobServiceClient
import os
from zipfile import ZipFile
import time
from io import BytesIO
import pandas as pd


start_time = time.time()

# Retrieve environment variables
storage_account_name = os.getenv("STORAGE_ACCOUNT_NAME")
storage_account_key = os.getenv("STORAGE_ACCOUNT_KEY")

print(f"Storage Account Name: {storage_account_name}")
print(f"Storage Account Key: {storage_account_key}")

connection_string = f"DefaultEndpointsProtocol=https;AccountName={storage_account_name};AccountKey={storage_account_key};EndpointSuffix=core.windows.net"
blob_service_client = BlobServiceClient.from_connection_string(connection_string)

# Blob and container details
container_name = "btcdata"
blob_name = "btcusd_1-day_data.csv.zip"

# Create BlobServiceClient
blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)

# Download blob content
download_stream = blob_client.download_blob()
file_content = download_stream.readall()  # Read the content as bytes
file_stream = BytesIO(file_content)

# Read the CSV file directly from the ZIP
with ZipFile(file_stream) as z:
    # List files in the ZIP
    print(z.namelist())  # Optional: Check the contents of the ZIP file

    # Open the desired CSV file and load it into a DataFrame
    with z.open("btcusd_1-day_data.csv") as f:  # Replace with your specific file name
        df = pd.read_csv(f)

print(df.head())

end_time = time.time()

execution_time = end_time - start_time
print(f"Script executed in {execution_time:.4f} seconds.")