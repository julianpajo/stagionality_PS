#!/bin/bash


# Function to display usage information
usage() {
    echo "Usage: $(basename "$0") -t <docker image tag>"
    echo "Description: Script to build docker images of this project."
    echo "Options:"
    echo "  -t <docker image tag>   Specify the docker image tag"
}

# Parse command line options
while getopts ":t:" option; do
    case "${option}" in
        t) docker_image_tag=${OPTARG} ;;
        *) usage ;;
    esac
done

# Check if docker_image_tag is set
if [ -z "$docker_image_tag" ]; then
    echo "Error: Missing docker image tag."
    usage
fi

services=("docker_postgis" "db_ps" "oauth2proxy" "geoserver" "keycloak" "keycloak_postgres" "gui" "restapi" "traefik")

for service in "${services[@]}"; do
    cd "$service"
    . build.sh -t $docker_image_tag
    cd ..
done

