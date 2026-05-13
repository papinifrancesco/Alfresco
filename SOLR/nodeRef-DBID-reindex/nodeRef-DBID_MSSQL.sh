#!/bin/bash

# File containing the UUIDs (one UUID per line)
uuid_file="nodeRef.txt"

# Microsoft SQL Server parameters
user="alfresco"
password="alfresco"
host="FQDN"
port="1433"
database="alfresco"

# Read the file line by line
while IFS= read -r uuid; do
  # Do the SQL Server query for each UUID
  sqlcmd -C -S "$host,$port" -U "$user" -P "$password" -d "$database" -h -1 -W -s "," -Q "SET NOCOUNT ON; SELECT id FROM alf_node WHERE uuid='$uuid';" < /dev/null
done < "$uuid_file"
