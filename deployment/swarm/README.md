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

You can create it with this command:

```bash
docker network create -d overlay euler-dev
docker network create -d overlay traefik-public
```

#### Docker secrets

The docker secrets needed are:

- postgres_password
- keycloak_postgres_passwd
- keycloak_admin_passwd
- keycloak_admin

You can create it with this command:

```bash
docker secret create {secret name} -
```

with the secret name instead of **{secret name}**.

After the **-** insert the secret value and press two times **Ctrl + D**.


### Generate deploy yaml

In order to generate the deploy yaml execute the **update.sh** script

### Create all the folders for volumes

To persist data, you need to create a bunch of folders.
Create the necessary volumes by executing this command:

```bash
sudo mkdir -p /data/development/docker_data/postgres/db
sudo mkdir -p /data/development/docker_data/traefik
sudo mkdir -p /data/development/docker_data/traefik/userfiles
sudo touch /data/development/docker_data/traefik/traefik.log
sudo touch /data/development/docker_data/traefik/access.log
sudo mkdir -p /data/development/docker_data/postgres-keycloak/db
```

### Update /etc/hosts file with local development domains

Open the **/etc/hosts** file with 

```bash
sudo nano /etc/hosts
```

and add the following domains in the /etc/hosts file:

- 172.18.0.1   euler.local
- 172.18.0.1   displacement.euler.local
- 172.18.0.1   auth.euler.local

### Deploy stack yaml

In order to deploy the swarm execute the **deploy.sh** script