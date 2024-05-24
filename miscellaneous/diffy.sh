#!/bin/bash

# Check if two arguments (files) are passed to the script
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 file1.properties file2.properties"
    exit 1
fi

# Input files
file1=$1
file2=$2

# Temporary files to store filtered and sorted lines
temp_file1=$(mktemp)
temp_file2=$(mktemp)
temp_keys=$(mktemp)

# Output file
output="output.txt"

# Function to filter, sort, and check for duplicates
process_file() {
    local input_file=$1
    local output_file=$2
    local temp_sorted=$(mktemp)

    # Filter lines and sort
    grep -v '^\s*#' "$input_file" | grep -v '^\s*$' | sort > "$temp_sorted"

    # Check for duplicates
    duplicate=$(awk -F= '{print $1}' "$temp_sorted" | uniq -d)
    if [ ! -z "$duplicate" ]; then
        while IFS= read -r key; do
            echo "$key is present multiple times in $input_file: check it!"
        done <<< "$duplicate"
        rm "$temp_sorted"
        exit 1
    fi

    # Copy sorted file without duplicates to the temporary output file
    mv "$temp_sorted" "$output_file"
}

# Process file1 and file2
process_file "$file1" "$temp_file1"
process_file "$file2" "$temp_file2"

# Extract keys from both files, sort, eliminate duplicates
awk -F= '{print $1}' "$temp_file1" "$temp_file2" | sort | uniq > "$temp_keys"

# Write unique keys' results to fichier_clés.txt
cp "$temp_keys" "fichier_clés.txt"

# Empty the output file if it already exists
> $output

# Compare files based on unique keys
while IFS= read -r key; do
    # Find the key in both files
    line1=$(grep "^$key=" "$temp_file1")
    line2=$(grep "^$key=" "$temp_file2")

    if [ -z "$line1" ]; then
        # If the key is not found in the first file
        echo "file1: \"nothing\"" >> $output
        echo "file2: $line2" >> $output
    elif [ -z "$line2" ]; then
        # If the key is not found in the second file
        echo "file1: $line1" >> $output
        echo "file2: \"nothing\"" >> $output
    elif [ "$line1" != "$line2" ]; then
        # If values are different
        echo "file1: $line1" >> $output
        echo "file2: $line2" >> $output
    fi
    echo "" >> $output # add a blank line to separate pairs
done < "$temp_keys"

# Clean up temporary files
rm "$temp_file1" "$temp_file2" "$temp_keys"

echo "Results written to $output"
