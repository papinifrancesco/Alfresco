# Load Tomcat Native Library
#LD_LIBRARY_PATH=/opt/alfresco/common/lib:$LD_LIBRARY_PATH

JAVA_HOME=/opt/alfresco/java
JRE_HOME=$JAVA_HOME
JAVA_OPTS="-XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -Djava.awt.headless=true -Dalfresco.home=/opt/alfresco -XX:ReservedCodeCacheSize=128m $JAVA_OPTS "
JAVA_OPTS="-Dcom.sun.management.jmxremote -Dsun.security.ssl.allowUnsafeRenegotiation=true $JAVA_OPTS "
JAVA_OPTS="-XX:NewRatio=2 -XX:+CMSParallelRemarkEnabled -XX:ParallelGCThreads=2 -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true $JAVA_OPTS "
JAVA_OPTS="-Xms4G -Xmx4G $JAVA_OPTS " # java-memory-settings
export JAVA_HOME
export JRE_HOME
export JAVA_OPTS
#export LD_LIBRARY_PATH
