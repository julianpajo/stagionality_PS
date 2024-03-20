ALTER SYSTEM SET logging_collector TO true;
ALTER SYSTEM SET log_statement TO 'none';
ALTER SYSTEM SET log_min_duration_statement TO 3000;
ALTER SYSTEM SET log_checkpoints TO true;
ALTER SYSTEM SET log_temp_files TO 0;