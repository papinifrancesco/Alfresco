#!/bin/bash

TS=/opt/alfresco/transform-service

FILE=alfresco-shared-file-store-controller

PATTERN=shared-file-store

JAVA_OPTS="$JAVA_OPTS                                \
  -Xms1g                                             \
  -Xmx1g                                             \
  -Dspring.servlet.multipart.max-file-size=8192MB    \
  -Dspring.servlet.multipart.max-request-size=8192MB \
  -Dserver.port=8099                                 \
  -Dserver.error.include-message=ALWAYS              \
  -Dlogging.level.org.alfresco.store=warn            \
  -DfileStorePath="$TS"/tmp/Alfresco                 \
  -Dscheduler.contract.path="$TS"/tmp/scheduler.json \
  -Dscheduler.content.age.millis=900000              \
  -Dscheduler.cleanup.interval=900000"               ;

/opt/alfresco/java/bin/java ${JAVA_OPTS} -jar $FILE >> $TS/logs/$PATTERN.out 2>> $TS/logs/$PATTERN.err &
