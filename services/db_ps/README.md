# Rheticus PS database

### Known issues
* export from pgadmin includes materialized views
* export from pgadmin doesn't include tablespaces creation
* export procedure needs to be documented

### Prerequisites for dockerization

* git
* Docker version>=17.12.1~ce-0~ubuntu

### Environment variables to be set (see [postgres-docker](https://hub.docker.com/_/postgres))

* POSTGRES_PASSWORD or (POSTGRES_PASSWORD_FILE using docker secrets)
* POSTGRES_USER
* PGDATA
* POSTGRES_DB
* POSTGRES_INITDB_WALDIR
* PROJECT_USER 
* PROJECT_PASSWORD (PROJECT_PASSWORD_FILE using docker secrets)


### Persisting data

If you want to persist data, you need to create a bunch of volumes/folders.
If you opt for folders you'll need:

- *pg_data/db_ssd1* mounted onto */var/lib/postgresql/hdd1* 
- *pg_data/db_hdd1* mountd onto */var/lib/postgresql/ssd1*


**ssd1** is setted as **default tablespace**


To create folders:

    sudo mkdir -p pg_data/db_ssd1
	sudo mkdir -p pg_data/db_hdd1
	sudo chown -R 999:999 pg_data


### Run container

docker run --rm -it --name rheticus_db -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=admin -e POSTGRES_DB=UNIBA -e PROJECT_USER=uniba -e PROJECT_PASSWORD=admin -v ./pg_data/db_hdd1:/var/lib/postgresql/hdd1 -v ./pg_data/db_ssd1:/var/lib/postgresql/ssd1 -p 5435:5432 stagionality_ps-db:develop


### Troubleshooting

If you encounter the problem  **ERROR:  directory "/var/lib/postgresql/hdd1/PG_12_201909212" already in use as a tablespace** you have to delete and recreate the folder.

    sudo rm -r pg_data/db_ssd1
	sudo rm -r pg_data/db_hdd1
	sudo mkdir -p pg_data/db_ssd1
	sudo mkdir -p pg_data/db_hdd1
	sudo chown -R 999:999 pg_data



### Prepare the docker image


##### Build docker image as "develop"
    ./build.sh -t develop