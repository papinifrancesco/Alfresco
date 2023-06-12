# Load Tomcat Native Library
LD_LIBRARY_PATH=/opt/alfresco/tomcat/lib:$LD_LIBRARY_PATH

CATALINA_PID=/opt/alfresco/tomcat/temp/catalina.pid

JAVA_HOME=/opt/alfresco/java

JRE_HOME=$JAVA_HOME


JAVA_OPTS="$JAVA_OPTS                                                                           \
           -Dalfresco.home=/opt/alfresco                                                        \
           -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true                        \
           -Dcom.sun.management.jmxremote                                                       \
           -Djava.awt.headless=true                                                             \
           -Dencryption.keystore.type=JCEKS                                                     \
           -Dencryption.keystore.provider=SunJCE                                                \
           -Dencryption.cipherAlgorithm=DESede/CBC/PKCS5Padding                                 \
           -Dencryption.keyAlgorithm=DESede                                                     \
           -Dencryption.keystore.location=/opt/alfresco/alf_data/keystore/keystore              \
           -Dmetadata-keystore.password=mp6yc0UD9e                                              \
           -Dmetadata-keystore.aliases=metadata                                                 \
           -Dmetadata-keystore.metadata.password=oKIWzVdEdA                                     \
           -Dmetadata-keystore.metadata.algorithm=AES                                           \
           -Djavax.net.ssl.keyStore=/opt/alfresco/alf_data/keystore/ssl.keystore                \
           -Djavax.net.ssl.keyStorePassword=keystore                                            \
           -Djavax.net.ssl.keyStoreType=JCEKS                                                   \
           -Djavax.net.ssl.trustStore=/opt/alfresco/alf_data/keystore/ssl.truststore            \
           -Djavax.net.ssl.trustStorePassword=kT9X6oe68t                                        \
           -Djavax.net.ssl.trustStoreType=JCEKS                                                 \
           -XX:+CMSParallelRemarkEnabled                                                        \
           -XX:+DisableExplicitGC                                                               \
           -XX:NewRatio=2                                                                       \
           -XX:OnOutOfMemoryError='$CATALINA_HOME/bin/shutdown.sh -force'                       \
           -XX:ParallelGCThreads=16                                                             \
           -XX:ReservedCodeCacheSize=128m                                                       \
           -Xdebug                                                                              \
           -verbose:gc                                                                          \
           -Xlog:gc*                                                                            \
           -Xlog:gc:/opt/alfresco/tomcat/logs/gc.log:tags,time,uptime,level                     \
           -Xms4G                                                                               \
           -Xmx4G                                                                               \
           -Xrunjdwp:transport=dt_socket,address=*:8000,server=y,suspend=n                      \
           -verbose:gc                                                                         ";


export CATALINA_PID

export JAVA_HOME

export JRE_HOME

export JAVA_OPTS

export LD_LIBRARY_PATH
