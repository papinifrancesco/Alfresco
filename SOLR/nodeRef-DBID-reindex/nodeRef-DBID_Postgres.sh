#!/bin/bash

# File containing the UUIDs (one UUID per line)
uuid_file="nodeRef.txt"

# PostgreSQL parameters
user="alfresco"
password="alfresco"
host="FQDN"
port="5432"
database="alfresco"

export PGPASSWORD="$password"

# Read the file line by line
while IFS= read -r uuid; do
  # Do the PostgreSQL query for each UUID
  psql -U "$user" -h "$host" -p "$port" -d "$database" -t -A -c "SELECT id FROM alf_node WHERE uuid='$uuid';"
done < "$uuid_file"
