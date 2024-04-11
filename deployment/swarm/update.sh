#!/bin/bash

docker-compose --env-file ./config/.deploy.env -f stack-dev.yml  config > euler.yml
docker-compose --env-file ./config/.deploy.env -f stack-auth.yml  config > auth.yml

echo "euler.yml and keycloak.yml created succesfully"

files=("euler.yml" "auth.yml")

for file in "${files[@]}"; do
    # Check if the file exists
    if [ ! -f "$file" ]; then
        echo "File $file not found"
        continue
    fi

    # Find the first line starting with "name" and store it in a variable
    first_line=$(grep -n "^name" "$file" | head -n 1 | cut -d ":" -f 1)

    # If a line starts with "name", delete that line from the file
    if [ ! -z "$first_line" ]; then
        sed -i "${first_line}d" "$file"
    fi

    sed -i 's/published: "\([0-9]*\)"/published: \1/g' "$file"
    sed -i '/depends_on:/{n;s/:$//;s/^ */    - /}' "$file"
    sed -i '/depends_on:/{n;n;d;}' "$file"
done
