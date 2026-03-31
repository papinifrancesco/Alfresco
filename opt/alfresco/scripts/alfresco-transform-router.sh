#!/bin/bash
TS=/opt/alfresco/transform-service

FILE=alfresco-transform-router
PATTERN=transform-router

JAVA_OPTS="$JAVA_OPTS                                                                       \
  -Xmx2048m                                                                                 \
  -XX:+ExitOnOutOfMemoryError                                                               \
  -DCORE_AIO_URL=http://127.0.0.1:8090                                                      \
  -DCORE_AIO_QUEUE=org.alfresco.transform.engine.aio.acs                                    \
  -DFILE_STORE_URL=http://127.0.0.1:8099/alfresco/api/-default-/private/sfs/versions/1/file \
  -DACTIVEMQ_URL=failover:(tcp://127.0.0.1:61616)?timeout=3000                              \
  -Djava.io.tmpdir="$TS"/tmp"                                                               ;

/opt/alfresco/java/bin/java ${JAVA_OPTS} -jar $FILE > $TS/logs/$PATTERN.out 2> $TS/logs/$PATTERN.err &
echo $! > $TS/transform-router.pid
