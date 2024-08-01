curl -s --header "x-alfresco-search-secret: secret" "http://127.0.0.1:8983/solr/alfresco/afts?q=DOC_TYPE:UnindexedNode&rows=9999999&wt=csv&fl=DBID&cache=false&omitHeader=true" -o DBIDs.txt

tail -n +2 DBIDs.txt | while read -r DBID; do

  curl --header "x-alfresco-search-secret: secret" "http://127.0.0.1:8983/solr/admin/cores?action=PURGE&nodeid=$DBID"

  curl --header "x-alfresco-search-secret: secret" "http://127.0.0.1:8983/solr/admin/cores?action=REINDEX&nodeid=$DBID"

done

# In case we want to check what's going on, set these from Solr's GUI
# log4j.logger.org.alfresco.solr.SolrInformationServer=DEBUG
# log4j.logger.org.alfresco.solr.tracker.MetadataTracker=DEBUG
