#!/bin/sh

# Scarica il file da Google Drive utilizzando gdown
pip install gdown

mkdir -p src/development/data

gdown --id 1fnBiBr-jFcvomP5UbHaOpw62EzDxuzhs --output src/development/data/ps_measurements.csv
