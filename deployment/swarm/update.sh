#!/bin/bash

docker-compose --env-file .deploy.env -f stack-dev.yml  config > euler.yml

echo "euler.yml created succesfully"