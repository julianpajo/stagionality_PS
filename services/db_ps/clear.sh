#!/bin/bash

# Ask for user confirmation
read -p "You are clearing all the data, do you want to proceed? (Y/N): " choice

# Convert the response to uppercase
choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

# Check user's choice
if [ "$choice" = "Y" ]; then
    echo "Proceeding..."

    sudo rm -r /data/development/docker_data/postgres/db/
    sudo mkdir -p /data/development/docker_data/postgres/db/

    echo "All data cleared"
    
elif [ "$choice" = "N" ]; then
    echo "Exiting..."
    exit 0
else
    echo "Invalid choice, exiting..."
    exit 0
fi
