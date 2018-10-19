reset
# maybe you should edit your .bashrc file with:
export ALFRESCO_HOME="/opt/alfresco-content-services"

export CATALINA_HOME="/opt/alfresco-content-services/tomcat"
export CATALINA_BASE=$CATALINA_HOME
export TOMCAT_HOME=$CATALINA_HOME

export SOLR_HOME="/opt/alfresco-search-services/solrhome"

# extract the Alfresco archive in /opt/alfresco-content-services
# extract the Tomcat archive in /opt/alfresco-content-services/tomcat



# create these folders!
mkdir $ALFRESCO_HOME/amps_share
mkdir $ALFRESCO_HOME/modules
mkdir $ALFRESCO_HOME/modules/platform
mkdir $ALFRESCO_HOME/modules/share
mkdir $CATALINA_HOME/shared
mkdir $CATALINA_HOME/webapps

cp $ALFRESCO_HOME/web-server/webapps/*.war $CATALINA_HOME/webapps/

cp -r $ALFRESCO_HOME/web-server/shared/classes $CATALINA_HOME/shared/

# JDBC driver not needed:
# scp -r $AlfrescoBaseDir/web-server/lib $AlfrescoServer:$CATALINA_HOME/lib


# alfresco.xml and share.xml MUST be present in the destination folder
cp $ALFRESCO_HOME/web-server/conf/Catalina/localhost/*.xml $CATALINA_HOME/conf


# put an up to date PostegreSQL JDBC in $CATALINA_HOME/lib
# check that your version of the JDBC is supported by your version of Tomcat
cp postgresql-42.2.5.jar $CATALINA_HOME/lib


# check that $CATALINA_HOME/conf/catalina.properties has:
shared.loader=${catalina.base}/shared/classes


# check that $CATALINA_HOME/bin/setenv.sh exist and correct its contents:
export CATALINA_PID=/opt/alfresco-content-services/tomcat/temp/catalina.pid
export JAVA_HOME=/usr/java/jdk1.8.0_181-amd64
JAVA_OPTS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC $JAVA_OPTS "
JAVA_OPTS="-Xms3G -Xmx3G $JAVA_OPTS " # java-memory-settings
JAVA_OPTS="$JAVA_OPTS -XX:NewRatio=2 -XX:+CMSParallelRemarkEnabled -XX:ParallelGCThreads=1"
export JAVA_OPTS


# edit $CATALINA_HOME/shared/classes/alfresco-global.properties and check:
# about alfresco.host and share.host : put whatever you want (IP, hostname,
# FQDN) # but be consistent and consider that TLS have strict requirements
# (the server certificate must have a matching FQDN name)
dir.root=/opt/alfresco-content-services/alf_data
dir.keystore=${dir.root}/keystore
db.username=alfresco
db.password=alfresco
db.schema.update=true
db.driver=org.postgresql.Driver
db.url=jdbc:postgresql://192.168.122.45:5432/alfresco
alfresco.context=alfresco
alfresco.host=${localname}
alfresco.port=8080
alfresco.protocol=http
share.context=share
share.host=${localname}
share.port=8080
share.protocol=http
alfresco.rmi.services.host=0.0.0.0


# edit $CATALINA_HOME/conf/server.xml so that:
<Connector port="8080" 
    protocol="HTTP/1.1"
    connectionTimeout="20000"
   redirectPort="8443" />
# DO NOT define HTTPS/SSL in a basic installation


# edit $CATALINA_HOME/conf/tomcat-users.xml so that, for example:
 <role rolename="admin"/>
  <role rolename="manager"/>
  <role rolename="manager-gui"/>
  <role rolename="manager-status"/>
  <role rolename="manager-script"/>
  <role rolename="manager-jmx"/>
  <user username="manager" password="manager" roles="admin-gui,admin-script,manager-gui,manager-status,manager-script,manager-jmx"/>
  <user username="tomcat" password="tomcat" roles="manager,admin"/>


# unzip the .war files, don't let Tomcat do it (you can 
# but we want to make a few mods before Tomcat starts).
cd $CATALINA_HOME/webapps
unzip -d alfresco/ alfresco.war
unzip -d share/ share.war
unzip -d ROOT/ ROOT.war


# install AMPs , by default only $ALFRESCO_HOME/amps/alfresco-share-services.amp
java -jar $ALFRESCO_HOME/bin/alfresco-mmt.jar install $ALFRESCO_HOME/amps/alfresco-share-services.amp $CATALINA_HOME/webapps/alfresco/ -nobackup
java -jar $ALFRESCO_HOME/bin/alfresco-mmt.jar install $ALFRESCO_HOME/amps/alfresco-share-services.amp $CATALINA_HOME/webapps/alfresco.war -nobackup

# define logging for the web apps:
# $CATALINA_HOME/webapps/alfresco/WEB-INF/classes/log4j.properties
# $CATALINA_HOME/webapps/share/WEB-INF/classes/log4j.properties
log4j.appender.File.File=${catalina.base}/logs/alfresco.log


# to stop Tomcat, ALWAYS use:
$CATALINA_HOME/bin/shutdown.sh 300 -force


# on the DB server: PostgreSQL , psql
psql -U postgres
CREATE USER alfresco WITH PASSWORD 'alfresco';
CREATE DATABASE alfresco OWNER alfresco ENCODING 'utf8';
GRANT ALL PRIVILEGES ON DATABASE alfresco TO alfresco;


# Alfresco should start without problems!
$CATALINA_HOME/bin/startup.sh


######### LibreOffice install #########
# Libraries

yum install -y libXinerama     \
               libGLU          \
               libfontconfig   \
               libICE libSM    \
               libXrender      \
               libXext         \
               libcups         \               
               libcairo2       \
               libgl1-mesa-glx \
               cups-libs       \
               cairo


# download and extract LibreOffice for your platform
# http://docs.alfresco.com/6.0/concepts/supported-platforms-ACS.html
wget http://ftp.rz.tu-bs.de/pub/mirror/tdf/tdf-pub/libreoffice/stable/5.2.1/rpm/x86_64/LibreOffice_5.2.1_Linux_x86-64_rpm.tar.gz
tar -xzf LibreOffice_5.2.1_Linux_x86-64_rpm.tar.gz

# CD to the RPMS directory and remove any files with gnome , kde in the filename. 
rm *gnome* 
rm *kde*
rm *freedesktop-menus*
# yum install -y 
yum install -y *.rpm

# Ignore any desktop update not found error messages.  You can remove the rpm files after installation

# LibreOffice will be probably installed in /opt/LibreOffice5.2 make a symlink then
ln -sf /opt/libreoffice5.2/ /opt/alfresco-content-services/LibreOffice/

# jodConverter.maxTasksPerProcess=100
# Do not include a slash (/) at the end of the path:
# jodconverter.officeHome=/opt/alfresco/LibreOffice
vi $CATALINA_HOME/shared/classes/alfresco-global.properties


######### ImageMagick install NON FINITO#########
# EPEL is your friend, so:
yum install epel-release

# CONTROLLARE SOTTO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# decide how to install, two paths are possible both with pros and cons
# path 1 , easy install but everything is in different folders (as per FHS):
yum install -y ImageMagick ImageMagick-c++
# then you should find all that is asked in:
# http://docs.alfresco.com/community/tasks/imagemagick-config.html
# and edit the alfresco-global.properties accordingly
# locate -r /ExactWordToBeFound$  is your friend so
locate -r /convert$
locate -r /coders$
locate -r /ImageMagick$
######### ImageMagick install NON FINITO#########


######### Solr - same host - no SSL so far #########
# references: http://docs.alfresco.com/6.0/tasks/solr6-install-withoutSSL.html
#             http://docs.alfresco.com/6.0/concepts/external-properties-solr6.html
wget https://download.alfresco.com/cloudfront/release/community/SearchServices/1.2.0/alfresco-search-services-1.2.0.zip
unzip alfresco-search-services-1.2.0.zip
mv alfresco-search-services /opt/
vi /opt/alfresco-search-services/solrhome/conf/shared.properties
    # uncomment
alfresco.suggestable.property.0={http://www.alfresco.org/model/content/1.0}name
alfresco.suggestable.property.1={http://www.alfresco.org/model/content/1.0}title 
alfresco.suggestable.property.2={http://www.alfresco.org/model/content/1.0}description 
alfresco.suggestable.property.3={http://www.alfresco.org/model/content/1.0}content
alfresco.cross.locale.datatype.0={http://www.alfresco.org/model/dictionary/1.0}text
alfresco.cross.locale.datatype.1={http://www.alfresco.org/model/dictionary/1.0}content
alfresco.cross.locale.datatype.2={http://www.alfresco.org/model/dictionary/1.0}mltext
    # modify
solr.baseurl=/solr -> solr.baseurl=/opt/alfresco-search-services/solr

# set SOLAR_HOME for solr
vi /opt/alfresco-search-services/solr.in.sh
# uncomment SOLR_HOME and add the path
SOLR_HOME=/opt/alfresco-search-services/solrhome

# start Solr , first time only command
/opt/alfresco-search-services/solr/bin/solr start -a "-Dcreate.alfresco.defaults=alfresco,archive"
# then you'll start it with just
/opt/alfresco-search-services/solr/bin/solr start

# restart Alfresco (don't know if it is needed, have to try)
# TEST 1 - index version number should increase
# open http://192.168.122.44:8983/solr/#/alfresco (your IP may be different)
# and note down the number in "Version:"
# go to http://192.168.122.44:8080/share/page/context/mine/myfiles and create a text file named: Solar
# type some text in it and save it
# go back to http://192.168.122.44:8983/solr/#/alfresco and check if "Current:" have the green V ,
# if not wait a little and then reload the page
# when the index is current, the number in "Version:" should be higher than your initial one
# TEST 2 - query for file name
# go to http://192.168.122.44:8983/solr/#/alfresco/query
# in the "q" field, remove "*.*" , type: Solar and then [Execute query]
# in the results you should have "response":{"numFound" : 1
# TEST 3 - query for typed text
# go to http://192.168.122.44:8983/solr/#/alfresco/query
# in the "q" field, remove "*.*" , type a word you typed when you created the file , [Execute query]
# in the results you should have "response":{"numFound" : 1


######### Tomcat SSL #########
# references: https://docs.alfresco.com/6.0/tasks/configure-ssl-test.html
vi $ALFRESCO_HOME/alf_data/keystore/generate_keystores.sh
# modify CERTIFICATE_VALIDITY from 36525 to no more than 36500
# modify as needed ALFRESCO_HOME , JAVA_HOME , and add:
mkdir $SOLR_HOME/keystore
cp "$CERTIFICATE_HOME/ssl.repo.client.keystore"                  "$SOLR_HOME/keystore/"
cp "$CERTIFICATE_HOME/ssl.repo.client.truststore"                "$SOLR_HOME/keystore/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-keystore-passwords.properties"   "$SOLR_HOME/keystore/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-truststore-passwords.properties" "$SOLR_HOME/keystore/"



##############CHECK AND SOLVE###########
# http://docs.alfresco.com/6.0/tasks/solr6-install.html
# ssl-keystore-passwords.properties
# ssl-truststore-passwords.properties
##############CHECK AND SOLVE###########

cp "$CERTIFICATE_HOME/ssl.repo.client.keystore"   "$SOLR_HOME/alfresco/conf/"
cp "$CERTIFICATE_HOME/ssl.repo.client.truststore" "$SOLR_HOME/alfresco/conf/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-keystore-passwords.properties" "$SOLR_HOME/keystore/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-truststore-passwords.properties" "$SOLR_HOME/keystore/"

cp "$CERTIFICATE_HOME/ssl.repo.client.keystore"   "$SOLR_HOME/archive/conf/"
cp "$CERTIFICATE_HOME/ssl.repo.client.truststore" "$SOLR_HOME/archive/conf/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-keystore-passwords.properties" "$SOLR_HOME/keystore/"
cp "$ALFRESCO_KEYSTORE_HOME/ssl-truststore-passwords.properties" "$SOLR_HOME/keystore/"

# so that everything will be copied in the right place

vi $CATALINA_HOME/conf/server.xml
# the keystorePass is the default one, do not use it in production
<Connector
port="8443"
URIEncoding="UTF-8"
protocol="org.apache.coyote.http11.Http11Protocol"
SSLEnabled="true"
maxThreads="150"
scheme="https"
keystoreFile="/opt/alfresco-content-services/alf_data/keystore/ssl.keystore"
keystorePass="kT9X6oe68t"
keystoreType="JCEKS"
secure="true" connectionTimeout="240000"
clientAuth="false"
sslProtocol="TLS"
allowUnsafeLegacyRenegotiation="true"
maxHttpHeaderSize="32768"
sslEnabledProtocols="TLSv1.2" />

vi $CATALINA_HOME/shared/classes/alfresco-global.properties
# change to:
alfresco.port=8443
alfresco.protocol=https
share.port=8443
share.protocol=https
# and restart Tomcat , from the browser you should be able to connect with HTTPS (even if with a lot of warnings)



######### Solr - same host - SSL #########
# references:   :http//docs.alfresco.com/6.0/tasks/solr6-install.html
#               http://docs.alfresco.com/6.0/tasks/generate-keys-solr4.html

# remove or move both alfresco and archive
mv $SOLR_HOME/alfresco $SOLR_HOME/alfresco.ORIG
mv $SOLR_HOME/archive  $SOLR_HOME/archive.ORIG

#then start Solr
/opt/alfresco-search-services/solr/bin/solr start -a "-Dcreate.alfresco.defaults=alfresco,archive"

vi /opt/alfresco-search-services/solr.in.sh
# modify so that you'll have
SOLR_SSL_KEY_STORE=$SOLR_HOME/keystore/ssl.repo.client.keystore
SOLR_SSL_KEY_STORE_PASSWORD=kT9X6oe68t
SOLR_SSL_KEY_STORE_TYPE=JCEKS
SOLR_SSL_TRUST_STORE=$SOLR_HOME/keystore/ssl.repo.client.truststore
SOLR_SSL_TRUST_STORE_PASSWORD=kT9X6oe68t
SOLR_SSL_TRUST_STORE_TYPE=JCEKS
SOLR_SSL_NEED_CLIENT_AUTH=true
SOLR_SSL_WANT_CLIENT_AUTH=false


# modify: alfresco.secureComms=none
# to:     alfresco.secureComms=https     
vi $SOLR_HOME/alfresco/conf/solrcore.properties
vi $SOLR_HOME/solrhome/archive/conf/solrcore.properties

# restart solr and test you can reach its website.

cd /opt/
reset ; egrep --color -R 'ssl.repo.client.keystore' *
reset ; updatedb ; locate -r keystore$ | grep -v templates | while read file; do ls -ltr $file; done | sort
reset ; updatedb ; locate -r keystore$ | grep -v templates | while read file; do sha1sum $file; done | sort
reset ; updatedb ; locate -r store.passwords.properties | grep -v templates | while read file; do echo $file ; enca -L none $file; done

keytool -list -keystore ssl.repo.client.keystore -storetype JCEKS -storepass kT9X6oe68t
keytool -importkeystore -srckeystore ssl.repo.client.keystore.jks -srcstoretype JCEKS -destkeystore ssl.repo.client.keystore.p12 -deststoretype pkcs12
