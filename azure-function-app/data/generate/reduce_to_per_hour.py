import pandas as pd

# Load the CSV file: https://www.kaggle.com/datasets/mczielinski/bitcoin-historical-data/data
input_file = "btcusd_1-min_data.csv"
output_file = "btcusd_1-hour_data.csv"

# Read the CSV into a DataFrame
df = pd.read_csv(input_file)

# Convert the Unix timestamp to a datetime and extract the hour (with the date)
df['Hour'] = pd.to_datetime(df['Timestamp'], unit='s').dt.floor('H')  # Floor to the start of the hour

# Aggregate data by hour
hourly_data = df.groupby('Hour').agg({
    'Open': 'first',  # First value of the hour
    'High': 'max',    # Maximum value of the hour
    'Low': 'min',     # Minimum value of the hour
    'Close': 'last',  # Last value of the hour
    'Volume': 'sum'   # Sum of the hour's volume
}).reset_index()

# Save the hourly data to a new CSV
hourly_data.to_csv(output_file, index=False)

print(f"Hourly data saved to {output_file}")