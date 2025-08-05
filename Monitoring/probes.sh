# only BASIC checks here!
# To convert and to adapt to your monitoring solution such as
# Nagios, Prometeus, Xymon, Zabbix etc. is up to you 


#########  ACS  #########
REPO="http://172.30.31.52:8080"

curl -s -X GET "$REPO/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-" -H  "accept: application/json"
curl -s -X GET "$REPO/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-"  -H  "accept: application/json"
#########  ACS  #########





#########  ActiveMQ #########
# brokerName has to be defined in:
# /opt/activemq/conf/activemq.xml
# usually the line is this one:
    <broker xmlns="http://activemq.apache.org/schema/core" brokerName="localhost" dataDirectory="${activemq.data}">

AMQ="http://172.30.31.55:8161"

curl --noproxy '*' -u admin:admin -H "Origin: http://localhost" -s $AMQ/api/jolokia/exec/org.apache.activemq:type=Broker,brokerName=localhost,service=Health/healthStatus | jq -r '{value, timestamp}'

curl --noproxy '*' -u admin:admin -H "Origin: http://localhost" -s $AMQ/api/jolokia/read/org.apache.activemq:brokerName=localhost,destinationName=org.alfresco.transform.engine.aio.acs,destinationType=Queue,type=Broker/QueueSize | jq '{value, timestamp}'
{
  "value": 0,
  "timestamp": 1754400976
}

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
ASS="http://172.30.31.57:8983"

curl --noproxy '*' -s -H "x-alfresco-search-secret: secret" -X GET "$ASS/solr/alfresco/admin/ping?&wt=json" | jq
curl --noproxy '*' -s -H "x-alfresco-search-secret: secret" -X GET "$ASS/solr/alfresco/afts?q=DOC_TYPE:ErrorNode&wt=json" | jq 
curl --noproxy '*' -s -H "x-alfresco-search-secret: secret" -X GET "$ASS/solr/alfresco/afts?q=DOC_TYPE:ErrorNode&wt=json" | jq '{lastIndexedTxTime, txRemaining, numFound: .response.numFound}'
#########  SOLR  #########
