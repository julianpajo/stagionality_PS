\connect "EULER"

COPY euler.ps_measurements FROM '/docker-entrypoint-initdb.d/data/ps_measurements.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"');