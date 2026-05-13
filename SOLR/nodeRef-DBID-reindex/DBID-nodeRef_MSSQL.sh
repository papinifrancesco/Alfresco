#!/bin/bash

# File containing the node IDs / DBIDs (one ID per line)
id_file="DBID.txt"

# Microsoft SQL Server parameters
user="alfresco"
password="alfresco"
host="FQDN"
port="1433"
database="alfresco"

# Read the file line by line
while IFS= read -r id; do
  # Do the SQL Server query for each DBID
  sqlcmd -S "$host,$port" -U "$user" -P "$password" -d "$database" -h -1 -W -s "," -Q "SET NOCOUNT ON; SELECT uuid FROM alf_node WHERE id=$id;"
done < "$id_file"
