#!/bin/bash

# Init constants
BASE_IMAGE_LOCATION=dockerhub.euler.it
PROJECT_NAME=stagionality_ps
REPO_NAME="docker_postgis"

# Function to display usage information
usage() {
    echo "Usage: $(basename "$0") -t <docker image tag>"
    echo "Description: Script to build docker images of this project."
    echo "Options:"
    echo "  -t <docker image tag>   Specify the docker image tag"
}

# Parse command line options
while getopts ":t:" option; do
    echo "Option: $option, OPTARG: $OPTARG"  # Debug output
    case "${option}" in
        t)
            docker_image_tag=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

echo "docker_image_tag: $docker_image_tag"  # Debug output

# Check if docker_image_tag is set
if [ -z "$docker_image_tag" ]; then
    echo "Error: Missing docker image tag."
    usage
fi

# Construct image name
image_name="${BASE_IMAGE_LOCATION}/${PROJECT_NAME}-${REPO_NAME}:${docker_image_tag}"

echo "Image name: $image_name"  # Debug output

# Build Docker image
docker build -t "$image_name" .

echo "Docker image built successfully with tag: $image_name"
