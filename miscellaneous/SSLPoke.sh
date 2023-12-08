

if [ -f SSLPoke.class ]; then
    echo "SSLPoke.class already compiled"
else
    echo "Compiling SSLPoke.class"
    /opt/alfresco/java/bin/javac SSLPoke.java
fi


/opt/alfresco/java/bin/javac SSLPoke.java

#OPTS="-Djavax.net.debug=all -Djavax.net.ssl.trustStore=/opt/alfresco/java/lib/security/cacerts"


#STORE=/opt/alfresco/alf_data/keystore/ssl.truststore

STORE=ssl.truststore

STOREPASS=kT9X6oe68t



OPTS="-Djavax.net.debug=all                             \
      -Djavax.net.ssl.trustStore=$STORE                 \
      -Djavax.net.ssl.trustStore.password=$STOREPASS    \
      -Djavax.net.ssl.trustStoreType=JCEKS             ";



PORT=443

SITE=hazelcast.com





#/opt/alfresco/java/bin/keytool -list -v -keystore $STORE -storepass $STOREPASS


/opt/alfresco/java/bin/java $OPTS SSLPoke $SITE $PORT
