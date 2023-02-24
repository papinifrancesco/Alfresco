#!/bin/bash
TS=/opt/alfresco/transform-service
WDIR=$TS

FILE=alfresco-transform-core-aio-boot
PATTERN=transform-core-aio

JAVA_OPTS="$JAVA_OPTS                                                                        \
  -Xmx4g                                                                                     \
  -DTRANSFORM_ENGINE_REQUEST_QUEUE=org.alfresco.transform.engine.aio.acs                     \
  -DPDFRENDERER_EXE=/opt/alfresco/alfresco-pdf-renderer/alfresco-pdf-renderer                \
  -DLIBREOFFICE_HOME=/opt/alfresco/libreoffice                                               \
  -DLIBREOFFICE_MAX_TASKS_PER_PROCESS=200                                                    \
  -DLIBREOFFICE_TIMEOUT=1200000                                                              \
  -DLIBREOFFICE_PORT_NUMBERS=8100                                                            \
  -DLIBREOFFICE_IS_ENABLED=true                                                              \
  -DIMAGEMAGICK_ROOT=/usr/lib64/ImageMagick-7.1.0                                            \
  -DIMAGEMAGICK_DYN=/usr/lib64/ImageMagick-7.1.0/lib                                         \
  -DIMAGEMAGICK_EXE=/usr/bin/convert                                                         \
  -DPDFBOX_NOTEXTRACTBOOKMARKS_DEFAULT=false                                                 \
  -DACTIVEMQ_URL=failover:(tcp://127.0.0.1:61616)?timeout=3000                               \
  -DFILE_STORE_URL=http://localhost:8099/alfresco/api/-default-/private/sfs/versions/1/file" ;

/opt/alfresco/java/bin/java ${JAVA_OPTS} -jar $FILE > $WDIR/logs/$PATTERN.out 2> $WDIR/logs/$PATTERN.err &

# IMAGEMAGICK_ROOT : CANNOT be empty or undefined
# undefined in application-default.yaml :
# LIBREOFFICE_TEMPLATE_PROFILE_DIR
# IMAGEMAGICK_CODERS
# IMAGEMAGICK_CONFIG
#   -DIMAGEMAGICK_CODERS=/usr/lib64/ImageMagick-7.0.10/modules-Q16HDRI/coders \
