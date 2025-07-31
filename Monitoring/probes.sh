# TAKE NOTES FIRST
# REORGANISE LATER


#########  ACS  #########

REPO="http://172.30.31.52:8080"

curl -s -X GET "$REPO/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" -H  "accept: application/json"
curl -s -X GET "$REPO/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-"  -H  "accept: application/json"

#########  ACS  #########





#########  ActiveMQ #########

# brokerName has to be defined in:
# /opt/activemq/conf/activemq.xml

AMQ="http://172.30.31.55:8161"

curl --noproxy '*' -u user:Apassword -s $AMQ/api/jolokia/exec/org.apache.activemq:type=Broker,brokerName=edoc-activemq,service=Health/healthStatus | jq -r '.value'

#########  ActiveMQ #########





#########  ATS #########
ATC="http://172.30.31.55:8090"
curl --noproxy '*' -s -X GET "$ATC/live"

ATR="http://172.30.31.55:8095"
curl --noproxy '*' -s -X GET "$ATR/live"

SFS="http://172.30.31.55:8099"
curl --noproxy '*' -s -X GET "$SFS/live"

# CaDES is a custom transformer : you don't have it
CDS="http://172.30.31.55:8097"
curl --noproxy '*' -s -X GET "$CDS/live"

#########  ATS #########





#########  SOLR  #########

curl --noproxy '*' -s -H "x-alfresco-search-secret: secret" -X GET "http://172.30.31.57:8983/solr/alfresco/admin/ping?&wt=json" | jq
curl --noproxy '*' -s -H "x-alfresco-search-secret: secret" -X GET "http://172.30.31.58:8983/solr/alfresco/admin/ping?&wt=json" | jq
curl --noproxy '*' -s -H "x-alfresco-search-secret: secret" -X GET "http://172.30.31.51:8983/solr/alfresco/admin/ping?&wt=json" | jq
  
curl --noproxy '*' -s -H "x-alfresco-search-secret: secret" -X GET "http://172.30.31.57:8983/solr/alfresco/afts?q=DOC_TYPE:ErrorNode&wt=json" | jq 

curl --noproxy '*' -s -H "x-alfresco-search-secret: secret" -X GET "http://172.30.31.57:8983/solr/alfresco/afts?q=DOC_TYPE:ErrorNode&wt=json" | jq '{lastIndexedTxTime, txRemaining, numFound: .response.numFound}'

#########  SOLR  #########
