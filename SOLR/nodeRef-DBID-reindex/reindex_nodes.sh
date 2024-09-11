#!/bin/bash

HEADER=x-alfresco-search-secret
URL=http://10.138.86.165:8983/solr/admin/cores
SECRET=secret

cat DBID.txt | while read -r DBID; do

  curl --header "$HEADER: $SECRET" "$URL?action=PURGE&nodeid=$DBID"

  curl --header "$HEADER: $SECRET" "$URL?action=REINDEX&nodeid=$DBID"

done
