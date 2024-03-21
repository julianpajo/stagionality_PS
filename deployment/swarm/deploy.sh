#!/bin/bash

# YAML file name
file="euler.yml"

# Check if the file exists
if [ ! -f "$file" ]; then
    echo "File $file not found"
fi

# Find the first line starting with "name" and store it in a variable
first_line=$(grep -n "^name" "$file" | head -n 1 | cut -d ":" -f 1)

# If a line starts with "name", delete that line from the file
if [ ! -z "$first_line" ]; then
    sed -i "${first_line}d" "$file"
fi

# Remove the quotes around numbers after the "published" string
sed -i 's/published: "\([0-9]*\)"/published: \1/g' "$file"


docker stack deploy -c euler.yml euler