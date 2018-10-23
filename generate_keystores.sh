#! /bin/sh
# original script, generate-keys.sh,  is missing a key piece: the emitting CA
# as far as Alfresco 6.0 CE, keystore and truststore contains 2 certs with self-explanatory names:
# ssl.alfresco.ca and ssl.repo
# so the certificate chain is validated and you have no issues at all having solr4 to use
# ssl.repo (verified: 5.2 installer puts Alfresco on http/8080 and sol4 on https/8443

# despite what the official documentation states, I was able to have Alfresco 6.0 CE and Solr6 work
# with just the generated, self-signed certs, and even a simple verification with:
# tcpdump -i lo -w AlfrescoSolrTLS.cap
# Wireshark , shows: Alert (Level: Fatal, Description: Unknown CA)

# also, your generate certs should have "subject alternative names" defined otherwise modern
# browsers will complain about such a missing field

# have a look at:
# https://angelborroy.wordpress.com/2016/06/15/configuring-alfresco-ssl-certificates/


# Please edit the variables below to suit your installation



# Alfresco installation directory
if [ -z "$ALFRESCO_HOME" ]; then
    ALFRESCO_HOME=/opt/alfresco
    echo "Setting ALFRESCO_HOME to $ALFRESCO_HOME"
fi

# The directory containing the alfresco keystores, as referenced by keystoreFile and truststoreFile attributes in tomcat/conf/server.xml
ALFRESCO_KEYSTORE_HOME=$ALFRESCO_HOME/alf_data/keystore

# Location in which new keystore files will be generated
if [ -z "$CERTIFICATE_HOME" ]; then
    CERTIFICATE_HOME=$HOME
    echo "Certificates will be generated in $CERTIFICATE_HOME and then moved to $ALFRESCO_KEYSTORE_HOME"
fi

# Java installation directory
JAVA_HOME=/usr/java/jdk1.8.0_181-amd64

# The repository server certificate subject name, as specified in tomcat/conf/tomcat-users.xml with roles="repository"
REPO_CERT_DNAME="CN=Alfresco Repository, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"

# The SOLR client certificate subject name, as specified in tomcat/conf/tomcat-users.xml with roles="repoclient"
SOLR_CLIENT_CERT_DNAME="CN=Alfresco Repository Client, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"

# The number of days before the certificate expires
# the original value, 36525 , seems too much and the issued certs have a validity of just ONE day
CERTIFICATE_VALIDITY=36500

# Stop
if [ -f "$ALFRESCO_HOME/alfresco.sh" ]; then "$ALFRESCO_HOME/alfresco.sh" stop; fi

# Ensure certificate output dir exists
mkdir -p "$CERTIFICATE_HOME"

# Remove old output files (note they are backed up elsewhere)
if [ -f "$CERTIFICATE_HOME/ssl.keystore" ]; then rm "$CERTIFICATE_HOME/ssl.keystore"; fi
if [ -f "$CERTIFICATE_HOME/ssl.truststore" ]; then rm "$CERTIFICATE_HOME/ssl.truststore"; fi
if [ -f "$CERTIFICATE_HOME/browser.p12" ]; then rm "$CERTIFICATE_HOME/browser.p12"; fi
if [ -f "$CERTIFICATE_HOME/ssl.repo.client.keystore" ]; then rm "$CERTIFICATE_HOME/ssl.repo.client.keystore"; fi
if [ -f "$CERTIFICATE_HOME/ssl.repo.client.truststore" ]; then rm "$CERTIFICATE_HOME/ssl.repo.client.truststore"; fi



# Generate new self-signed certificates for the repository and solr
"$JAVA_HOME/bin/keytool" -genkeypair -keyalg RSA -dname "$REPO_CERT_DNAME" -validity $CERTIFICATE_VALIDITY -alias ssl.repo -ext san=dns:localhost,dns:alfresco6.tst.lcl,ip:127.0.0.1,ip:192.168.122.44,ip:192.168.122.1 -keypass kT9X6oe68t -keystore "$CERTIFICATE_HOME/ssl.keystore" -storetype JCEKS -storepass kT9X6oe68t

"$JAVA_HOME/bin/keytool" -exportcert -alias ssl.repo -ext san=dns:localhost,dns:alfresco6.tst.lcl,ip:127.0.0.1,ip:192.168.122.44,ip:192.168.122.1 -file "$CERTIFICATE_HOME/ssl.repo.crt" -keystore "$CERTIFICATE_HOME/ssl.keystore" -storetype JCEKS -storepass kT9X6oe68t

"$JAVA_HOME/bin/keytool" -genkeypair -keyalg RSA -dname "$SOLR_CLIENT_CERT_DNAME" -validity $CERTIFICATE_VALIDITY -alias ssl.repo.client -ext san=dns:localhost,dns:alfresco6.tst.lcl,ip:127.0.0.1,ip:192.168.122.44,ip:192.168.122.1 -keypass kT9X6oe68t -keystore "$CERTIFICATE_HOME/ssl.repo.client.keystore" -storetype JCEKS -storepass kT9X6oe68t

"$JAVA_HOME/bin/keytool" -exportcert -alias ssl.repo.client -ext san=dns:localhost,dns:alfresco6.tst.lcl,ip:127.0.0.1,ip:192.168.122.44,ip:192.168.122.1 -file "$CERTIFICATE_HOME/ssl.repo.client.crt" -keystore "$CERTIFICATE_HOME/ssl.repo.client.keystore" -storetype JCEKS -storepass kT9X6oe68t


# Create trust relationship between repository and solr
"$JAVA_HOME/bin/keytool" -importcert -noprompt -alias ssl.repo.client -file "$CERTIFICATE_HOME/ssl.repo.client.crt" -keystore "$CERTIFICATE_HOME/ssl.truststore" -storetype JCEKS -storepass kT9X6oe68t

# Create trust relationship between repository and itself - used for searches
"$JAVA_HOME/bin/keytool" -importcert -noprompt -alias ssl.repo -file "$CERTIFICATE_HOME/ssl.repo.crt" -keystore "$CERTIFICATE_HOME/ssl.truststore" -storetype JCEKS -storepass kT9X6oe68t

# Create trust relationship between solr and repository
"$JAVA_HOME/bin/keytool" -importcert -noprompt -alias ssl.repo -file "$CERTIFICATE_HOME/ssl.repo.crt" -keystore "$CERTIFICATE_HOME/ssl.repo.client.truststore" -storetype JCEKS -storepass kT9X6oe68t

# Export repository keystore to pkcs12 format for browser compatibility
"$JAVA_HOME/bin/keytool" -importkeystore -srckeystore "$CERTIFICATE_HOME/ssl.keystore" -srcstorepass kT9X6oe68t -srcstoretype JCEKS -srcalias ssl.repo -srckeypass kT9X6oe68t -destkeystore "$CERTIFICATE_HOME/browser.p12" -deststoretype pkcs12 -deststorepass alfresco -destalias ssl.repo -destkeypass alfresco

# Export solr keystore to pkcs12 format for browser compatibility
"$JAVA_HOME/bin/keytool" -importkeystore -srckeystore "$CERTIFICATE_HOME/ssl.repo.client.keystore" -srcstorepass kT9X6oe68t -srcstoretype JCEKS -srcalias ssl.repo.client -srckeypass kT9X6oe68t -destkeystore "$CERTIFICATE_HOME/browser-solr.p12" -deststoretype pkcs12 -deststorepass alfresco -destalias ssl.repo.client -destkeypass alfresco


# Ensure keystore dir actually exists
mkdir -p "$ALFRESCO_KEYSTORE_HOME"

# Back up old files
cp "$ALFRESCO_KEYSTORE_HOME/ssl.keystore"   "$ALFRESCO_KEYSTORE_HOME/ssl.keystore.old"
cp "$ALFRESCO_KEYSTORE_HOME/ssl.truststore" "$ALFRESCO_KEYSTORE_HOME/ssl.truststore.old"
cp "$ALFRESCO_KEYSTORE_HOME/browser.p12"    "$ALFRESCO_KEYSTORE_HOME/browser.p12.old"

# Install the new files
cp "$CERTIFICATE_HOME/ssl.keystore"   "$ALFRESCO_KEYSTORE_HOME/ssl.keystore"
cp "$CERTIFICATE_HOME/ssl.truststore" "$ALFRESCO_KEYSTORE_HOME/ssl.truststore"
cp "$CERTIFICATE_HOME/browser.p12"    "$ALFRESCO_KEYSTORE_HOME/browser.p12"



mkdir -p $SOLR_HOME/keystore
cp "$CERTIFICATE_HOME/ssl.repo.client.keystore"                  "$SOLR_HOME/keystore/"
cp "$CERTIFICATE_HOME/ssl.repo.client.truststore"                "$SOLR_HOME/keystore/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-keystore-passwords.properties"   "$SOLR_HOME/keystore/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-truststore-passwords.properties" "$SOLR_HOME/keystore/"

##############CHECK AND SOLVE###########
# http://docs.alfresco.com/6.0/tasks/solr6-install.html
# ssl-keystore-passwords.properties
# ssl-truststore-passwords.properties
##############CHECK AND SOLVE###########

cp "$CERTIFICATE_HOME/ssl.repo.client.keystore"                  "$SOLR_HOME/alfresco/conf/"
cp "$CERTIFICATE_HOME/ssl.repo.client.truststore"                "$SOLR_HOME/alfresco/conf/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-keystore-passwords.properties"   "$SOLR_HOME/alfresco/conf/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-truststore-passwords.properties" "$SOLR_HOME/alfresco/conf/"


cp "$CERTIFICATE_HOME/ssl.repo.client.keystore"                  "$SOLR_HOME/archive/conf/"
cp "$CERTIFICATE_HOME/ssl.repo.client.truststore"                "$SOLR_HOME/archive/conf/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-keystore-passwords.properties"   "$SOLR_HOME/archive/conf/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-truststore-passwords.properties" "$SOLR_HOME/archive/conf/"

# so that everything will be copied in the right place


echo " "
echo "*******************************************"
echo "You must copy the following files to the correct location."
echo " "
echo " $CERTIFICATE_HOME/ssl.repo.client.keystore"
echo " $CERTIFICATE_HOME/ssl.repo.client.truststore"
echo " eg. for Solr 4 the location is SOLR_HOME/workspace-SpacesStore/conf/ and SOLR_HOME/archive-SpacesStore/conf/"
echo " "
echo "$ALFRESCO_KEYSTORE_HOME/browser.p12 has also been generated."
echo " "
echo "Please ensure that you set dir.keystore=$ALFRESCO_KEYSTORE_HOME in alfresco-global.properties"
echo "*******************************************"
