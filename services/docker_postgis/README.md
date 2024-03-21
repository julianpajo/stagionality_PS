# PostGIS Docker image

This repository creates a basic PostGIS Docker image, using the official PostgreSQL image - [postgres-docker](https://hub.docker.com/_/postgres).
In particular, this is a modified version of the [docker-postgis](https://hub.docker.com/r/postgis/postgis/) project, adapted for the case.

The current supported version is PostgreSQL 11 - PostGIS 2.5, using most of the code provided [here](https://github.com/postgis/docker-postgis/tree/master/11-2.5).

## Usage

To build and run the Docker image please refer to the following sections. Please note that this image is supposed to be used as base image for
project-specific PostGIS databases. 


### Build

To build a new Docker image, you need to run the [`build.sh`](build.sh) script. For information of how to use it, please refer to the help:
```
./build.sh -h
```

### Run

In order to run the container, you need to provide a few environment variables. The full list is available in the [postgres-docker](https://hub.docker.com/_/postgres)
documentation. 

Some variables you MUST provide: 

- `POSTGRES_USER` - username of the postgres admin user, which has got full privileges
- `POSTGRES_PASSWORD` or  -  password of the postgres admin user
- `POSTGRES_DB` - main DB created at DBMS initialization
- `PROJECT_USER` - main user of the DB for this project
- `PROJECT_PASSWORD` - main user password

If you use [Docker secrets](https://docs.docker.com/engine/swarm/secrets/) you can provide credentials using the corresponding 
`POSTGRES_PASSWORD_FILE` and `PROJECT_PASSWORD_FILE` variables.


To run the container:
```
docker run -it --name <container_name> \
    -e PROJECT_USER=<project_usr> -e PROJECT_PASSWORD=<project_pwd> \
    -e POSTGRES_PASSWORD=<postgres_pwd> -e POSTGRES_DB=<database_name> \
    -p 5432:5432 -v /local/path/to/db_data/:/var/lib/postgresql/data \
    -d dockerhub.planetek.it/pkt309_team_eretico/docker_postgis:<tag>
```
