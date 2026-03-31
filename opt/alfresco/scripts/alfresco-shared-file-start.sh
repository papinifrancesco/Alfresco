#!/bin/bash
TS=/opt/alfresco/transform-service

FILE=alfresco-shared-file-store-controller
PATTERN=shared-file-store

JAVA_OPTS="$JAVA_OPTS                                                          \
  -Xmx2g                                                                       \
  -XX:+ExitOnOutOfMemoryError                                                  \
  -Dspring.servlet.multipart.max-file-size=8192MB                              \
  -Dspring.servlet.multipart.max-request-size=8192MB                           \
  -Dserver.port=8099                                                           \
  -Dserver.error.include-message=ALWAYS                                        \
  -Dlogging.level.org.alfresco.store=warn                                      \
  -DfileStorePath=/opt/alfresco/transform-service/tmp/Alfresco                 \
  -Dscheduler.contract.path=/opt/alfresco/transform-service/tmp/scheduler.json \
  -Dscheduler.content.age.millis=3600000                                       \
  -Dscheduler.cleanup.interval=3600000                                         \
  -Djava.io.tmpdir=/opt/alfresco/transform-service/tmp"

/opt/alfresco/java/bin/java ${JAVA_OPTS} -jar $FILE > "$TS"/logs/$PATTERN.out 2> "$TS"/logs/$PATTERN.err &
echo $! > "$TS"/shared-file-store.pid
