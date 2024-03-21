# README

### Init a new swarm

In order to deploy a docker swarm you have to init it with this command:

```bash
docker swarm init
```

### Create Docker Networks and secrets

#### Docker networks

The docker networks needed are:

- uniba-dev

You can create it with this command:

```bash
docker network create -d overlay uniba-dev
```

#### Docker secrets

The docker secrets needed are:

- postgres_password

You can create it with this command:

```bash
docker secret create postgres_password -
```

after the **-** insert the secret value and press two times **Ctrl + D**.


### Generate deploy yaml

In order to generate the deploy yaml execute the **update.sh** script

### Create all the folders for volumes

To persist data, you need to create a bunch of folders.
Create the necessary volumes by executing this command:

```bash
sudo mkdir -p /data/development/docker_data/postgres/db
```

### Deploy stack yaml

In order to deploy the swarm execute the **deploy.sh** script