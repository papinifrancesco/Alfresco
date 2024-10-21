# TAKE NOTES FIRST
# REORGANISE LATER


#########  ACS  #########

curl -s -X GET "http://172.30.31.51:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" -H  "accept: application/json"

curl -s -X GET "http://172.30.31.51:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-"  -H  "accept: application/json"


curl -s -X GET "http://172.30.31.52:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" -H  "accept: application/json"

curl -s -X GET "http://172.30.31.52:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-"  -H  "accept: application/json"



curl -s -X GET "http://172.30.31.52:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" -H  "accept: application/json"

curl -s -X GET "http://172.30.31.52:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-"  -H  "accept: application/json"

#########  ACS  #########




#########  ActiveMQ #########

# brokerName has to be defined in:
# /opt/activemq/conf/activemq.xml

curl --noproxy '*' -u user:Apassword -s http://127.0.0.1:8161/api/jolokia/exec/org.apache.activemq:type=Broker,brokerName=edoc-activemq,service=Health/healthStatus | jq -r '.value'

#########  ActiveMQ #########




#########  ATS #########

curl --noproxy '*' -s -X GET "http://172.30.31.55:8090/live"
curl --noproxy '*' -s -X GET "http://172.30.31.56:8090/live"
curl --noproxy '*' -s -X GET "http://172.30.31.51:8090/live"

curl --noproxy '*' -s -X GET "http://172.30.31.55:8095/live"
curl --noproxy '*' -s -X GET "http://172.30.31.56:8095/live"
curl --noproxy '*' -s -X GET "http://172.30.31.51:8095/live"

curl --noproxy '*' -s -X GET "http://172.30.31.55:8099/live"
curl --noproxy '*' -s -X GET "http://172.30.31.56:8099/live"
curl --noproxy '*' -s -X GET "http://172.30.31.51:8099/live"

# CaDES
curl --noproxy '*' -s -X GET "http://172.30.31.55:8097/live"
curl --noproxy '*' -s -X GET "http://172.30.31.56:8097/live"
curl --noproxy '*' -s -X GET "http://172.30.31.51:8097/live"





#########  ATS #########


#########  SOLR  #########

EPOCH="$(date +%s)" ; curl -s -H "x-alfresco-search-secret: secret" "http://172.30.31.57:8983/solr/alfresco/admin/ping?_=$EPOCH&ts=$EPOCH&wt=json' | jq
  
curl -s --header "x-alfresco-search-secret: secret" -X GET "http://172.30.31.57:8983/solr/alfresco/afts?q=DOC_TYPE:ErrorNode&wt=json" | jq 

curl --noproxy '*' -s --header "x-alfresco-search-secret: secret" -X GET "http://172.30.31.57:8983/solr/alfresco/afts?q=DOC_TYPE:ErrorNode&wt=json" | jq '{lastIndexedTxTime, txRemaining, numFound: .response.numFound}'

#########  SOLR  #########