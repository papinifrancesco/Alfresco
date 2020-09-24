# Load Tomcat Native Library
#LD_LIBRARY_PATH=/opt/alfresco/common/lib:$LD_LIBRARY_PATH

JAVA_HOME=/opt/alfresco/java
JRE_HOME=$JAVA_HOME
JAVA_OPTS="-XX:+DisableExplicitGC -Djava.awt.headless=true -Dalfresco.home=/opt/alfresco -Dcom.sun.management.jmxremote -Dsun.security.ssl.allowUnsafeRenegotiation=true -XX:ReservedCodeCacheSize=128m $JAVA_OPTS "
# DEPRECATED: -XX:+UseConcMarkSweepGC -Xloggc -XX:+PrintGCDetails
JAVA_OPTS="-Xms12G -Xmx12G $JAVA_OPTS " # java-memory-settings
JAVA_OPTS="$JAVA_OPTS -XX:NewRatio=2 -XX:+CMSParallelRemarkEnabled -XX:ParallelGCThreads=4"
#JAVA_OPTS="$JAVA_OPTS -Doracle.net.tns_admin=/usr/lib/oracle/12.1/client64/network/admin/"
#GC_LOGS="-verbose:gc  -Xlog:gc*  -Xlog:gc:/opt/alfresco/tomcat/logs/gc_$(hostname)_alf_$(date '+%Y%m%d-%H%M%S').log"
JAVA_OPTS="$JAVA_OPTS $GC_LOGS" # java-memory-settings
JAVA_OPTS="$JAVA_OPTS -XX:OnOutOfMemoryError='$CATALINA_HOME/bin/shutdown.sh -force' -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true"
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStoreType=JCEKS -Djavax.net.ssl.trustStore=/opt/alfresco/tomcat/shared/classes/ldaps_keystore.jceks"
JAVA_OPTS="$JAVA_OPTS -Doracle.net.tns_admin=/opt/alfresco/tomcat/shared/classes/"
export JAVA_HOME
export JRE_HOME
export JAVA_OPTS
export LD_LIBRARY_PATH
export TNS_ADMIN=/opt/alfresco/tomcat/shared/classes/
export CATALINA_OPTS="$CATALINA_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,address=*:8000,server=y,suspend=n"
export PATH=/usr/local/Centera_SDK/lib/64:$PATH
export LD_LIBRARY_PATH=/usr/local/Centera_SDK/lib/64:$LD_LIBRARY_PATH
