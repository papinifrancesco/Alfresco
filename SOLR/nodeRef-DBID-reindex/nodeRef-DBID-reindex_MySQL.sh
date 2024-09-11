# We're given a response.json file with the nodeRef identified as "id" , first we have to clean it
python3 ./filter.py > noderRef.txt

# We have to get the DBID from the DB (MySQL in this case)
./nodeRef-DBID.sh 2>/dev/null > DBID.txt

# We send SOLR a PURGE and REINDEX action for each DBID
./reindex_nodes.sh
