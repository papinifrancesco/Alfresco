#!/bin/bash
# make it a cron job
/usr/bin/curl -u admin:admin -H "Origin: http://localhost" -H "Content-Type: application/json" -X POST -d '{"type":"exec","mbean":"org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=ActiveMQ.DLQ","operation":"purge"}' "http://127.0.0.1:8161/api/jolokia/"
