#!/bin/bash

docker-compose --env-file .deploy.env -f stack-dev.yml  config > stagionality.yml

echo "stagionality.yml created succesfully"