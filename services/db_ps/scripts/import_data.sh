#!/bin/bash

# Scarica il file da Google Drive utilizzando gdown
pip install gdown

echo ""
echo "Downloading data . . ."
echo ""

gdown --id 1fnBiBr-jFcvomP5UbHaOpw62EzDxuzhs --output ps_measurements.csv

# Variabili di connessione
DB_NAME="EULER"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"
CSV_PATH="ps_measurements.csv"

# Prompt per la password

echo ""
echo "Inserisci la password per l'utente $DB_USER:"
read -s DB_PASSWORD
echo ""
echo "Importing data in database. It may takes some minutes . . ."
echo ""

# Comando psql per copiare i dati dal file CSV nel database
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\COPY euler.ps_measurements FROM '$CSV_PATH' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"');"

# Verifica dell'esecuzione del comando
if [ $? -eq 0 ]; then
  echo ""
  echo "Data imported succesfully"
  echo ""
  rm ps_measurements.csv
else
  echo "Errore durante l'importazione dei dati."
fi
