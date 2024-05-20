FROM dockerhub.euler.it/stagionality_ps-docker_postgis:develop

WORKDIR /usr/local/db_ps/
COPY ./src/ ./src/

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD pg_isready -U postgres || exit 1

RUN mv ./src/development/* /docker-entrypoint-initdb.d/