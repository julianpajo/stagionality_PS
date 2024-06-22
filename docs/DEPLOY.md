# README

### Init a new swarm

In order to deploy a docker swarm you have to init it with this command:

```bash
docker swarm init
```

### Create Docker Networks and secrets

#### Docker networks

The docker networks needed are:

- euler-dev
- traefik-public
- auth

You can create it with this command:

```bash
docker network create -d overlay euler-dev
docker network create -d overlay traefik-public
docker network create -d overlay auth
```

#### Docker secrets

The docker secrets needed are:

- postgres_passwd
- keycloak_postgres_passwd
- keycloak_admin_passwd

You can create it with this command:

```bash
docker secret create {secret name} -
```

with the secret name instead of **{secret name}**.

After the **-** insert the secret value and press two times **Ctrl + D**.


### Create all the folders for volumes

To persist data, you need to create a bunch of folders.
Create the necessary volumes by executing this command:

```bash
# volumes for stack-dev
sudo mkdir -p /data/development/docker_data/postgres/db
sudo mkdir -p /data/development/docker_data/geoserver/data

#volumes for stack-auth
sudo mkdir -p /data/development/docker_data/postgres-keycloak/db

#volumes for stack-traefik
sudo mkdir -p /data/development/docker_data/traefik
sudo mkdir -p /data/development/docker_data/traefik/userfiles
sudo touch /data/development/docker_data/traefik/traefik.log
sudo touch /data/development/docker_data/traefik/access.log

```

### Update /etc/hosts file with local development domains

Open the `/etc/hosts` file with 

```bash
sudo nano /etc/hosts
```

and add the following domains in the /etc/hosts file:

- 172.18.0.1   euler.local
- 172.18.0.1   displacement.euler.local
- 172.18.0.1   auth.euler.local
- 172.18.0.1   geoserver.euler.local


### Generate deploy yaml

In order to generate the deploy yaml, navigate to the deployment path in `/path/to/project/stagionality_ps/deployment/swarm` and execute the `update.sh` script.

### Build all docker images

Navigate to the services path in `/path/to/project/stagionality_ps/services` and execute the `build_all.sh` script.

### Deploy stack yaml

In order to deploy the swarm, navigate back to the deployment path and execute the `deploy.sh` script.

### How to setup the services

In order to set up the services and ensure everything runs correctly, please follow the tutorial [here](TUTORIAL.md).