import pandas as pd

# Percorso del file di input e output
input_file = 'ps_measurements.csv'
output_file = 'output.csv'

# Carica il file CSV in un DataFrame
df = pd.read_csv(input_file)

# Funzione per estrarre l'ultima misurazione dalla stringa di misurazioni
def extract_last_measurement(measurement_str):
    measurements = measurement_str.strip('{}').split(',')
    last_measurement = measurements[-1].strip('"[]')
    return last_measurement

# Applica la funzione per estrarre l'ultima misurazione alla colonna 'measurement' e assegna il risultato alla nuova colonna 'last_measurement'
df['last_measurement'] = df['measurement'].apply(extract_last_measurement)

# Salva il DataFrame modificato in un nuovo file CSV
df.to_csv(output_file, index=False)

print("Output CSV creato con successo.")
