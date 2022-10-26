# NOT READY YET!!!
# MYSQL specific
# The goal of this script is to get a quick overview of how many nodes in the DB can be indexed by SOLR

# DATABASE SERVER OR PROXY
DB_SERVER=172.16.0.191

# DATABASE SERVER PORT OR PROXY
DB_PORT=6446

DB_USER=alfresco

DB_PASSWORD=Alfresc0pwd+

# the file with the query
SQL_QUERY=/root/work/alfresco_nodes.sql

# temporary TSV file
TSV_FILE=/root/work/alfresco_nodes.tsv

# report cleaned of unwanted elements
CLEAN_REPORT=/root/work/alfresco_nodes.txt

mysql -h $DB_SERVER -P $DB_PORT -u $DB_USER -p'$DB_PASSWORD' < $SQL_QUERY > $TSV_FILE

grep -v 'cm_content_nodes' $TSV_FILE      | \
grep -v 'versionHistory'                  | \
grep -v 'thumbnail'                       | \
grep -v 'failedThumbnail' > $CLEAN_REPORT   ;

# get the first column (the one with the numbers)
# and sum them all
awk 'BEGIN {FS="\t"}; {print $1}' $CLEAN_REPORT | \
paste -sd+ | bc                                   ;
