#!/bin/sh

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env 'PROJECT_PASSWORD'

# Perform all actions as $POSTGRES_USER
# note: PGUSER is a postgres env var
export PGUSER="$POSTGRES_USER"

export PJUSER="$PROJECT_USER" 
export PJPASSWORD="$PROJECT_PASSWORD"

# Load PostGIS into $POSTGRES_DB
echo "Loading PostGIS extensions into $POSTGRES_DB"
"${psql[@]}" --dbname="$POSTGRES_DB" <<-EOSQL
	CREATE SCHEMA postgis;
	CREATE SCHEMA tiger;
	CREATE SCHEMA topology;
	ALTER DATABASE "$POSTGRES_DB" SET search_path TO public,pg_catalog,postgis,topology,tiger,pgcrypto,dblink;
EOSQL

"${psql[@]}" --dbname="$POSTGRES_DB" <<-EOSQL
	CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA postgis;
	CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;
	CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;
	CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder WITH SCHEMA tiger;
	CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;
	CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;
	CREATE EXTENSION IF NOT EXISTS pg_prewarm SCHEMA public;
EOSQL

if [ "$PJUSER" ] && [ "$PJPASSWORD" ]; then 
	"${psql[@]}" --dbname="$POSTGRES_DB" <<-EOSQL
		CREATE ROLE $PJUSER;
		ALTER ROLE $PJUSER WITH SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD '$PJPASSWORD';
	EOSQL
fi