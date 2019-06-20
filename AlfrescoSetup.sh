reset

# on the DB server: PostgreSQL , psql
psql -U postgres
CREATE USER alfresco WITH PASSWORD 'alfresco';
CREATE DATABASE alfresco OWNER alfresco ENCODING 'utf8';
GRANT ALL PRIVILEGES ON DATABASE alfresco TO alfresco;

# on the repository machine 
# we don't want run Alfresco as root so let's create a dedicated group and a dedicated user
groupadd alfresco
useradd -m alfresco -p alfresco -g alfresco


# maybe you should edit your .bashrc file with:
export ALFRESCO_HOME="/opt/alfresco"
export ALFRESCO_KEYSTORE_HOME="/opt/alfresco/alf_data/keystore"

export CATALINA_HOME="/opt/alfresco/tomcat"
export CATALINA_BASE=$CATALINA_HOME
export TOMCAT_HOME=$CATALINA_HOME

export SOLR_HOME="/opt/solr/solrhome"

# extract the Alfresco archive in /opt/alfresco
# extract the Tomcat archive in /opt/alfresco/tomcat



# create these folders!
mkdir $ALFRESCO_HOME/amps_share
mkdir $ALFRESCO_HOME/modules
mkdir $ALFRESCO_HOME/modules/platform
mkdir $ALFRESCO_HOME/modules/share
mkdir $CATALINA_HOME/shared
mkdir $CATALINA_HOME/webapps
mkdir /usr/local/scripts

# remove what you don't need from Tomcat
rm -rf $CATALINA_HOME/webapps/docs/
rm -rf $CATALINA_HOME/webapps/examples/
rm -rf $CATALINA_HOME/webapps/ROOT/
# unzip the .war files, don't let Tomcat do it (you can 
# but we want to make a few mods before Tomcat starts).
unzip $ALFRESCO_HOME/web-server/webapps/alfresco.war -d $CATALINA_HOME/webapps/alfresco/
unzip $ALFRESCO_HOME/web-server/webapps/share.war -d $CATALINA_HOME/webapps/share/
unzip $ALFRESCO_HOME/web-server/webapps/_vti_bin.war -d $CATALINA_HOME/webapps/_vti_bin/
unzip $ALFRESCO_HOME/web-server/webapps/ROOT.war -d $CATALINA_HOME/webapps/ROOTA/


cp -r $ALFRESCO_HOME/web-server/shared/classes $CATALINA_HOME/shared/

# get the two scripts first , then:
cd /usr/local/scripts
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/all_logs_compress.sh
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/catalina_rotate.sh

chown alfresco:alfresco /usr/local/scripts/all_logs_compress.sh
chown alfresco:alfresco /usr/local/scripts/catalina_rotate.sh

chmod u+x *.sh
# in the end it should be like as:
# -rwxr--r-- 1 alfresco alfresco 66193 Jun 19 13:45 all_logs_compress.sh
# -rwxr--r-- 1 alfresco alfresco 67607 Jun 19 13:45 catalina_rotate.sh


crontab -u alfresco -e
# put the two lines below
55 23 * * * /usr/local/scripts/catalina_rotate.sh /opt/alfresco/tomcat > /dev/null 2>&1
59 23 * * * /usr/local/scripts/all_logs_compress.sh /opt/alfresco/tomcat > /dev/null 2>&1


# make alfresco user able to start, stop, restart and check the status of both alfresco.service and solr.service
visudo
---
# Allows members of the alfresco group to start and stop alfresco service
%alfresco ALL= NOPASSWD: /bin/systemctl start   alfresco.service
%alfresco ALL= NOPASSWD: /bin/systemctl stop    alfresco.service
%alfresco ALL= NOPASSWD: /bin/systemctl restart alfresco.service
%alfresco ALL= NOPASSWD: /bin/systemctl status  alfresco.service

# Allows members of the alfresco group to start and stop solr service
%alfresco ALL= NOPASSWD: /bin/systemctl start   solr.service
%alfresco ALL= NOPASSWD: /bin/systemctl stop    solr.service
%alfresco ALL= NOPASSWD: /bin/systemctl restart solr.service
%alfresco ALL= NOPASSWD: /bin/systemctl status  solr.service
---


# JDBC driver not needed:
# scp -r $AlfrescoBaseDir/web-server/lib $AlfrescoServer:$CATALINA_HOME/lib


# alfresco.xml and share.xml MUST be present in the destination folder
cp $ALFRESCO_HOME/web-server/conf/Catalina/localhost/*.xml $CATALINA_HOME/conf


# put a Tomcat supported version of PostegreSQL JDBC in $CATALINA_HOME/lib
# too old or too new might not work as expected, have a look at:
# https://docs.alfresco.com/6.0/concepts/supported-platforms-ACS.html
wget https://jdbc.postgresql.org/download/postgresql-42.2.5.jar -P $CATALINA_HOME/lib/



# check that $CATALINA_HOME/conf/catalina.properties has:
shared.loader=${catalina.base}/shared/classes,${catalina.base}/shared/lib/*.jar


# check that $CATALINA_HOME/bin/setenv.sh exist and correct its contents
# depending on your hardware: amount of RAM namely
cd $CATALINA_HOME/bin/
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/setenv.sh
chown alfresco. setenv.sh
chmod u+x setenv.sh


# edit $CATALINA_HOME/shared/classes/alfresco-global.properties and check:
# about alfresco.host and share.host : put whatever you want (IP, hostname,
# FQDN) # but be consistent and consider that TLS have strict requirements
# (the server certificate must have a matching FQDN name)
dir.root=/opt/alfresco/alf_data
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
 <Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               URIEncoding="UTF-8" maxHttpHeaderSize="32768"
               redirectPort="8443" />
       [...]
  <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log." suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b %I %T" />
               
# DO NOT define HTTPS/SSL in a basic installation


# mv $CATALINA_HOME/conf/tomcat-users.xml to .ORIG and copy the
# provided tomcat.users.xml from this Github repo
cd $CATALINA_HOME/conf/
mv tomcat-users.xml tomcat-users.xml.ORIG
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/tomcat-users.xml

# unblock the /manager webapp
# if Tomcat < 8.0
vi $CATALINA_HOME/conf/context.xml
# and comment that Valve below
<!--
<Valve className="org.apache.catalina.authenticator.SSLAuthenticator" securePagesWithPragma="false" />
-->

# if Tomcat >= 8.0
vi $CATALINA_HOME/webapps/manager/META-INF/context.xml
# and comment the Valve this way
<!--
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
-->



# install AMPs , by default only $ALFRESCO_HOME/amps/alfresco-share-services.amp
java -jar $ALFRESCO_HOME/bin/alfresco-mmt.jar install $ALFRESCO_HOME/amps/alfresco-share-services.amp $CATALINA_HOME/webapps/alfresco/ -nobackup


# define logging for the web apps:
# $CATALINA_HOME/webapps/alfresco/WEB-INF/classes/log4j.properties
log4j.appender.File.File=${catalina.base}/logs/alfresco.log
# $CATALINA_HOME/webapps/share/WEB-INF/classes/log4j.properties
log4j.appender.File.File=${catalina.base}/logs/share.log





######### LibreOffice install #########


# download and extract LibreOffice for your platform
# http://docs.alfresco.com/6.1/concepts/supported-platforms-ACS.html
cd /root/work/
wget https://downloadarchive.documentfoundation.org/libreoffice/old/5.4.6.2/rpm/x86_64/LibreOffice_5.4.6.2_Linux_x86-64_rpm.tar.gz
tar -xzf LibreOffice_5.4.6.2_Linux_x86-64_rpm.tar.gz

# CD to the RPMS directory and remove any files with gnome , kde in the filename. 
rm *gnome* 
rm *kde*
rm *freedesktop-menus*
# yum install -y 
yum install *.rpm -y

# Ignore any desktop update not found error messages.  You can remove the rpm files after installation

# LibreOffice will be probably installed in /opt/LibreOffice5.2 make a symlink then
ln -sf /opt/libreoffice5.4/ /opt/alfresco/LibreOffice


# Libraries : check first IF this ones are missing
rpm -q libXinerama     \
       libGLU          \
       libfontconfig   \
       libICE          \
       libSM           \
       libXrender      \
       libXext         \
       libcups         \
       libcairo2       \
       libgl1-mesa-glx \
       cups-libs       \
       cairo           ;
       
# in my case, I had to install:
yum install libGLU libfontconfig libcups libcairo2 libgl1-mesa-glx cups-libs cairo -y ;



# jodConverter.maxTasksPerProcess=100
# Do not include a slash (/) at the end of the path:
# jodconverter.officeHome=/opt/alfresco/LibreOffice
vi $CATALINA_HOME/shared/classes/alfresco-global.properties


######### ImageMagick install #########
# EPEL is your friend, so:
yum install epel-release

# ImageMagick installation process is not that clear but try to get a .rpm for it and force the installation
# probably the installer will complain but there are high chances that will get a working installation... for
# Alfresco at least (in the end just "convert" is used).

# the key point is that we WILL NOT have a root directory so in alfresco-global.properties define
# an empty root folder (see the provided file):
wget https://github.com/ImageMagick/ImageMagick/archive/7.0.7-39.tar.gz

# unnecessary on Centos 7 :
#wget https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz

img.root=
img.dyn=/usr/lib64
img.exe=/usr/bin/convert
img.coders=/usr/lib64/ImageMagick-7.0.8/modules-Q16HDRI/coders
img.config=/etc/ImageMagick-7

######### ImageMagick install #########


######### Solr - same host - no SSL so far #########
# references: http://docs.alfresco.com/6.0/tasks/solr6-install-withoutSSL.html
#             http://docs.alfresco.com/6.0/concepts/external-properties-solr6.html
wget https://download.alfresco.com/cloudfront/release/community/SearchServices/1.2.0/alfresco-search-services-1.2.0.zip
unzip alfresco-search-services-1.2.0.zip
mv alfresco-search-services /opt/
vi /opt/solr/solrhome/conf/shared.properties
    # uncomment
alfresco.suggestable.property.0={http://www.alfresco.org/model/content/1.0}name
alfresco.suggestable.property.1={http://www.alfresco.org/model/content/1.0}title 
alfresco.suggestable.property.2={http://www.alfresco.org/model/content/1.0}description 
alfresco.suggestable.property.3={http://www.alfresco.org/model/content/1.0}content
alfresco.cross.locale.datatype.0={http://www.alfresco.org/model/dictionary/1.0}text
alfresco.cross.locale.datatype.1={http://www.alfresco.org/model/dictionary/1.0}content
alfresco.cross.locale.datatype.2={http://www.alfresco.org/model/dictionary/1.0}mltext

# modify ONLY if you want to change Solr context (not even ASPI do this).
solr.baseurl=/solr -> solr.baseurl=/opt/solr/solr

# set SOLAR_HOME for solr
vi /opt/solr/solr.in.sh
# uncomment SOLR_HOME and add the path
SOLR_HOME=/opt/solr/solrhome
# and maybe change Java memory
SOLR_JAVA_MEM="-Xms2g -Xmx2g"


# start Solr , first time only command
/opt/solr/solr/bin/solr start -a "-Dcreate.alfresco.defaults=alfresco,archive"
# subsequent times you'll start it with just
/opt/solr/solr/bin/solr start

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



######### Alfresco-Tomcat , Solr-Jetty TLS certificates configuration #########

# generate_keystore.sh doesn't work for a variety of reasons
# it is way better to have a proper set-up with an emitting CA
# instead of self-signed certs trying to trust each other (BTW
# it doesn't work).

# using: /root/ca/intermediate/IL_ALFRESCO_SOLR_openssl.cnf
# and:   /root/ca/03_create_server_AlfrescoSolr.sh
# from https://github.com/papinifrancesco/OCSP
# we can generate a PKCS12 .p12 cert to be used by Alfresco 
# and Solr that contains the full certificate chain
# Before running the .sh remember to customize it and the
# .cnf as well according to your needs
# IMPORTANT : both OCSPs must be running all the time so run:
# 08_run_OCSP_responders.sh on the CA machine

# clean the everything but keystore* (these are Alfresco only files, no TLS related)
cd $ALFRESCO_KEYSTORE_HOME
(ls | grep -v '^keystore') | while read list; do rm -f $list; done


# then copy the .p12 to $ALFRESCO_KEYSTORE ,
# it should be /opt/alfresco/alf_data/keystore

# import the .p12 into a new keystore , I intentionally left default options
# for easier reading, in production environment we should change them
keytool -importkeystore -v \
        -srckeystore  alfresco6.tst.lcl.p12 -srcstoretype  PKCS12 -providerName SunJSSE -srcstorepass  alfresco   -srcalias 1 \
        -destkeystore ssl.keystore          -deststoretype JCEKS  -providerName SunJCE  -deststorepass kT9X6oe68t -destalias ssl.repo -destkeypass kT9X6oe68t

# if you, like me, have a base64 encoded CA chain, split it in single files (otherwise -alias won't work)
keytool -import -v -noprompt -trustcacerts -storetype JCEKS -providerName SunJCE -file rootCA.cert.pem         -alias rootca.ssl         -keystore ssl.keystore -storepass kT9X6oe68t
keytool -import -v -noprompt -trustcacerts -storetype JCEKS -providerName SunJCE -file intermediateCA.cert.pem -alias intermediateca.ssl -keystore ssl.keystore -storepass kT9X6oe68t

# create the truststore
keytool -import -v -noprompt -file rootCA.cert.pem            -alias rootca.ssl         -keystore ssl.truststore -storepass kT9X6oe68t -storetype JCEKS -providerName SunJCE
keytool -import -v -noprompt -file intermediateCA.cert.pem    -alias intermediateca.ssl -keystore ssl.truststore -storepass kT9X6oe68t -storetype JCEKS -providerName SunJCE


# on CentOS, Fedora, RHEL - updating the ca trust won't hurt
# for other distros check the relative documentation
cp rootCA.cert.pem /etc/pki/ca-trust/source/anchors/
cp intermediateCA.cert.pem /etc/pki/ca-trust/source/anchors/
update-ca-trust export ; update-ca-trust

# create ssl-keystore-passwords.properties and ssl-truststore-passwords.properties
echo aliases=rootca.ssl,intermediateca.ssl,ssl.repo >> ssl-keystore-passwords.properties 
echo keystore.password=kT9X6oe68t                   >> ssl-keystore-passwords.properties 
echo rootca.ssl.password=kT9X6oe68t                 >> ssl-keystore-passwords.properties 
echo intermediateca.ssl.password=kT9X6oe68t         >> ssl-keystore-passwords.properties 
echo ssl.repo.password=kT9X6oe68t                   >> ssl-keystore-passwords.properties 

echo aliases=rootca.ssl,intermediateca.ssl          >> ssl-truststore-passwords.properties 
echo keystore.password=kT9X6oe68t                   >> ssl-truststore-passwords.properties 
echo rootca.ssl.password=kT9X6oe68t                 >> ssl-truststore-passwords.properties 
echo intermediateca.ssl.password=kT9X6oe68t         >> ssl-truststore-passwords.properties 





######### Tomcat SSL #########
# references: https://docs.alfresco.com/6.0/tasks/configure-ssl-test.html
# using default cert/keystore
mkdir $SOLR_HOME/keystore

# copy the original keystore to an instance for Solr, just to keep the scripts unchanged
# we could use one name "ssl.keystore" and "ssl.truststore" but then we should modify
# all of the configuration scripts accordingly; easier to copy a file
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl.keystore"   "$ALFRESCO_KEYSTORE_HOME/ssl.repo.client.keystore"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl.truststore" "$ALFRESCO_KEYSTORE_HOME/ssl.repo.client.truststore"

\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl.repo.client.keystore"            "$SOLR_HOME/keystore/"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl.repo.client.truststore"          "$SOLR_HOME/keystore/"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl-keystore-passwords.properties"   "$SOLR_HOME/keystore/"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl-truststore-passwords.properties" "$SOLR_HOME/keystore/"


\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl.repo.client.keystore"            "$SOLR_HOME/alfresco/conf/"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl.repo.client.truststore"          "$SOLR_HOME/alfresco/conf/"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl-keystore-passwords.properties"   "$SOLR_HOME/alfresco/conf/"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl-truststore-passwords.properties" "$SOLR_HOME/alfresco/conf/"


\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl.repo.client.keystore"            "$SOLR_HOME/archive/conf/"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl.repo.client.truststore"          "$SOLR_HOME/archive/conf/"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl-keystore-passwords.properties"   "$SOLR_HOME/archive/conf/"
\cp -f "$ALFRESCO_KEYSTORE_HOME/ssl-truststore-passwords.properties" "$SOLR_HOME/archive/conf/"
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
keystoreFile="/opt/alfresco/alf_data/keystore/ssl.keystore"
keystorePass="kT9X6oe68t"
keystoreProvider="SunJCE"
keystoreType="JCEKS"
secure="true" connectionTimeout="240000"
clientAuth="want"
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
mv $SOLR_HOME/alfresco ~/$SOLR_HOME/alfresco.ORIG
mv $SOLR_HOME/archive  ~/$SOLR_HOME/archive.ORIG

#then start Solr
/opt/solr/solr/bin/solr start -a "-Dcreate.alfresco.defaults=alfresco,archive"

vi /opt/solr/solr.in.sh
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





######### Apache reverse proxy - AJP #########
vi /opt/alfresco/tomcat/shared/classes/alfresco-global.properties

alfresco.host=alfresco.tst.lcl
alfresco.port=443
[...]
share.host=alfresco.tst.lcl
share.port=443


vi /opt/alfresco/tomcat/conf/server.xml

<Connector port="8009" protocol="AJP/1.3" redirectPort="8443" tomcatAuthentication="false" />


# then copy the previously generated key and certs to the Apache machine and edit:
vi /etc/httpd/conf.d/ssl.conf

# Server Certificate
SSLCertificateFile /etc/pki/tls/certs/alfresco6.tst.lcl.cert.pem
# Server Private Key
SSLCertificateKeyFile /etc/pki/tls/private/alfresco6.tst.lcl.key.pem
# Server Certificate Chain
SSLCertificateChainFile /etc/pki/tls/certs/ca-chain.cert.pem
# Certificate Authority (CA)
SSLCACertificateFile /etc/pki/tls/certs/rootCA.cert.pem
# Client Authentication (Type)
SSLVerifyClient optional


# REMEMBER : both OCSPs must be running all the time so run:
# 08_run_OCSP_responders.sh on the CA machine


# a basic configuration: everything Apache gets will be sent to:
# ajp://alfresco6.tst.lcl:8009/
vi /etc/httpd/conf.d/mod_proxy_ajp.conf

LoadModule proxy_ajp_module modules/mod_proxy_ajp.so

LogLevel Debug

ProxyPass / ajp://alfresco6.tst.lcl:8009/
ProxyPassReverse / ajp://alfresco6.tst.lcl:8009/




# restart Alfresco, restart Apache
$CATALINA_HOME/bin/shutdown.sh 90 -force ; $CATALINA_HOME/bin/startup.sh
apachectl restart


# to stop Tomcat, ALWAYS use:
$CATALINA_HOME/bin/shutdown.sh 300 -force
# Alfresco should start without problems!
$CATALINA_HOME/bin/startup.sh
