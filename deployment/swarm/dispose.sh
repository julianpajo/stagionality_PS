#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Rimozione di tutti gli stack..."
    docker stack rm traefik euler auth
else
    echo "Rimozione dello stack $1..."
    docker stack rm $1
fi
