#!/bin/bash

# Fichier contenant les UUIDs (chaque UUID sur une ligne)
uuid_file="nodeRef.txt"

# Paramètres MySQL
user="alfresco"
password="alfresco"
host="FQDN"
port="3306"
database="alfresco"

# Lire le fichier ligne par ligne
while IFS= read -r uuid; do
  # Exécuter la requête MySQL pour chaque UUID
  mysql -u "$user" -p"$password" -h "$host" -P "$port" -D "$database" --skip-column-names -e "SELECT id FROM alf_node WHERE uuid='$uuid';"
done < "$uuid_file"
