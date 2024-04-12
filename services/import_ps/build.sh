#!/bin/bash

BASE_IMAGE_LOCATION=dockerhub.euler.it
PROJECT_NAME=stagionality_ps
REPO_NAME="import_ps"

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

# Construct image name
base_image_name="${BASE_IMAGE_LOCATION}/${PROJECT_NAME}-${REPO_NAME}_base:${docker_image_tag}"
image_name="${BASE_IMAGE_LOCATION}/${PROJECT_NAME}-${REPO_NAME}:${docker_image_tag}"

# Build Docker image
docker build -f ./Dockerfile.base -t "$base_image_name" .
docker build -f ./Dockerfile --no-cache -t "$image_name" .

echo "Docker image built successfully with tag: $image_name"
