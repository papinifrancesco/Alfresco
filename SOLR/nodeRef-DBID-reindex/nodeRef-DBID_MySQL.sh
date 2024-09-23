#!/bin/bash

# File containing the UUIDs (one UUID per line)
uuid_file="nodeRef.txt"

# MySQL parameters
user="alfresco"
password="alfresco"
host="FQDN"
port="3306"
database="alfresco"

# Read the file line by line
while IFS= read -r uuid; do
  # Do the MySQL query for each UUID
  mysql -u "$user" -p"$password" -h "$host" -P "$port" -D "$database" --skip-column-names -e "SELECT id FROM alf_node WHERE uuid='$uuid';"
done < "$uuid_file"
