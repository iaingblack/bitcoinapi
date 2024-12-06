import pandas as pd

# Load the CSV file: https://www.kaggle.com/datasets/mczielinski/bitcoin-historical-data/data
input_file = "btcusd_1-min_data.csv"
output_file = "btcusd_1-day_data.csv"

# Read the CSV into a DataFrame
df = pd.read_csv(input_file)

# Convert the Unix timestamp to a datetime and extract the date
df['Date'] = pd.to_datetime(df['Timestamp'], unit='s').dt.date

# Aggregate data by day
daily_data = df.groupby('Date').agg({
    'Open': 'first',  # First value of the day
    'High': 'max',    # Maximum value of the day
    'Low': 'min',     # Minimum value of the day
    'Close': 'last',  # Last value of the day
    'Volume': 'sum'   # Sum of the day's volume
}).reset_index()

# Save the daily data to a new CSV
daily_data.to_csv(output_file, index=False)

print(f"Daily data saved to {output_file}")