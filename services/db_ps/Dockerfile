FROM dockerhub.euler.it/stagionality_ps-docker_postgis:develop

WORKDIR /usr/local/db_ps/
COPY ./src/ ./src/

RUN mv ./src/development/* /docker-entrypoint-initdb.d/