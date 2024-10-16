




curl -s -X GET "http://172.30.31.51:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" -H  "accept: application/json"

curl -s -X GET "http://172.30.31.51:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-"  -H  "accept: application/json"



curl -s -X GET "http://172.30.31.52:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" -H  "accept: application/json"

curl -s -X GET "http://172.30.31.52:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-"  -H  "accept: application/json"



curl -s -X GET "http://172.30.31.52:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" -H  "accept: application/json"

curl -s -X GET "http://172.30.31.52:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-"  -H  "accept: application/json"





EPOCH="$(date +%s)" ; curl -s -H "x-alfresco-search-secret: secret" "http://172.30.31.57:8983/solr/alfresco/admin/ping?_=$EPOCH&ts=$EPOCH&wt=json' | jq
  
  



curl -s --header "x-alfresco-search-secret: secret" -X GET "http://172.30.31.57:8983/solr/alfresco/afts?q=DOC_TYPE:ErrorNode&wt=json" | jq 
URL=