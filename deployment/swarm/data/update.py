import pandas as pd

def remove_column(input_file, output_file):
    # Read the CSV file using Pandas
    df = pd.read_csv(input_file)
    
    # Remove the 'old_scatterer_id' column if present
    if 'old_scatterer_id' in df.columns:
        df.drop(columns=['old_scatterer_id'], inplace=True)
    
    # Save the DataFrame to a new CSV file
    df.to_csv(output_file, index=False)

def invert_columns(input_file, output_file):
    # Read the CSV file using Pandas
    df = pd.read_csv(input_file)
    
    # Invert the order of columns
    df = df.iloc[:, ::-1]
    
    # Save the DataFrame to a new CSV file
    df.to_csv(output_file, index=False)

# Path of the input file
input_file = 'ps.csv'
# Path of the output file
output_file = 'ps.csv'

# Call the function to remove the column and save the new file
remove_column(input_file, output_file)

print("Operation completed. The 'old_scatterer_id' column has been removed, and the new file has been saved.")

# Additional part
# Path of the measurements CSV file
measurements_file = 'ps-measurements.csv'
# Path of the inverted measurements CSV file
inverted_measurements_file = 'ps-measurements.csv'

# Call the function to invert columns and save the new file
invert_columns(measurements_file, inverted_measurements_file)

print("Measurements CSV file inverted and saved as 'ps-measurements.csv'.")
