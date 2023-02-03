#!/bin/bash
TS=/opt/alfresco/transform-service
WDIR=$TS

FILE=alfresco-transform-router
PATTERN=transform-router

JAVA_OPTS="$JAVA_OPTS \
  -Xmx1g \
  -DCORE_AIO_URL=http://localhost:8090 \
  -DCORE_AIO_QUEUE=org.alfresco.transform.engine.aio.acs \
  -DFILE_STORE_URL=http://localhost:8099/alfresco/api/-default-/private/sfs/versions/1/file \
  -DACTIVEMQ_URL=failover:(tcp://127.0.0.1:61616)?timeout=3000"

/opt/alfresco/java/bin/java ${JAVA_OPTS} -jar $FILE >> $WDIR/logs/$PATTERN.out 2>> $WDIR/logs/$PATTERN.err &
