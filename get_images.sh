#!/bin/bash
folder="resources/images"
ini_file="files.ini"

echo "; File list generated on $(date)" > "$ini_file"
echo "" >> "$ini_file"

find "$folder" -maxdepth 1 -type f -printf "[%f]fullname=%p\n" >> "$ini_file"

# sort alphabetically
sort -o "$ini_file" "$ini_file"

echo "File list saved to $ini_file"