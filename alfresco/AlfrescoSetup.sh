reset

# to comply with https://docs.alfresco.com/content-services/latest/support/
# we have to to install a specific PostgreSQL version, for example 11.4: 
baseName="https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/postgresql11"
wget $baseName-11.4-1PGDG.rhel7.x86_64.rpm
wget $baseName-libs-11.4-1PGDG.rhel7.x86_64.rpm
wget $baseName-server-11.4-1PGDG.rhel7.x86_64.rpm
yum localinstall -y postgresql11*
/usr/pgsql-11/bin/postgresql-11-setup initdb
systemctl enable postgresql-11.service
systemctl start postgresql-11.service


# on the DB server: PostgreSQL , psql
sudo su postgres
psql -U postgres
CREATE USER alfresco WITH PASSWORD 'alfresco';
DROP DATABASE alfresco;
CREATE DATABASE alfresco OWNER alfresco ENCODING 'utf8';
GRANT ALL PRIVILEGES ON DATABASE alfresco TO alfresco;
\q

# also, configure Postgresql to LISTEN on all (or on given ones) interfaces
vim /var/lib/pgsql/11/data/postgresql.conf
listen_addresses = '*'                  # what IP address(es) to listen on;

# and ACCEPT connections from all (or from given ones) hosts
vim 
host    alfresco        alfresco        172.16.140.12/32        md5
host    alfresco        alfresco          10.11.12.13/32        md5


# restart the service to make the changes effective
systemctl restart postgresql-11.service



# on the repository machine 
# we don't want run Alfresco as root so let's create a dedicated group and a dedicated user
groupadd alfresco
useradd -m alfresco -g alfresco


# maybe you should edit your .bashrc file with:
export ALFRESCO_HOME="/opt/alfresco"
export ALFRESCO_KEYSTORE_HOME="$ALFRESCO_HOME/alf_data/keystore"

export CATALINA_HOME="$ALFRESCO_HOME/tomcat"
export CATALINA_BASE=$CATALINA_HOME
export TOMCAT_HOME=$CATALINA_HOME

export SOLR_HOME="/opt/solr/solrhome"


# this one below could be put in /etc/profile.d/MMT.sh
# so you'll have it for every user
alias MMT='/opt/alfresco/java/bin/java -jar /opt/alfresco/bin/alfresco-mmt.jar'

# extract the Alfresco archive in /opt/alfresco
# extract the Tomcat archive in /opt/alfresco/tomcat



# create these folders!
mkdir -p $ALFRESCO_HOME/amps_share
mkdir -p $ALFRESCO_HOME/alf_data/solr6Backup/alfresco
mkdir -p $ALFRESCO_HOME/alf_data/solr6Backup/archive
mkdir -p $ALFRESCO_HOME/modules/platform
mkdir -p $ALFRESCO_HOME/modules/share
mkdir -p $CATALINA_HOME/conf/Catalina/localhost
mkdir -p $CATALINA_HOME/scripts
mkdir -p $CATALINA_HOME/shared/classes/alfresco/extension/license
mkdir -p $CATALINA_HOME/shared/lib
mkdir -p $CATALINA_HOME/webapps
mkdir -p $CATALINA_HOME/logs/old

# remove what you don't need from Tomcat
rm -rf $CATALINA_HOME/webapps/docs/
rm -rf $CATALINA_HOME/webapps/examples/
rm -rf $CATALINA_HOME/webapps/ROOT/
# unzip the .war files, don't let Tomcat do it (you can 
# but we want to make a few mods before Tomcat starts).
unzip $ALFRESCO_HOME/web-server/webapps/alfresco.war -d $CATALINA_HOME/webapps/alfresco/
unzip $ALFRESCO_HOME/web-server/webapps/share.war -d $CATALINA_HOME/webapps/share/
unzip $ALFRESCO_HOME/web-server/webapps/_vti_bin.war -d $CATALINA_HOME/webapps/_vti_bin/
unzip $ALFRESCO_HOME/web-server/webapps/ROOT.war -d $CATALINA_HOME/webapps/ROOT/


cp -r $ALFRESCO_HOME/web-server/shared/classes $CATALINA_HOME/shared/

# get the script used to manage log rotation
cd $ALFRESCO_HOME/scripts
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/AlfrescoLogsManager.sh
chown alfresco. *.sh
chmod +x *.sh


# clean Tomcat's folders before starting it
cd $ALFRESCO_HOME/bin/
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/clean_tomcat_temp_work.sh
chmod u+x clean_tomcat_temp_work.sh


crontab -u alfresco -e
# put the two lines below
55 23 * * * /usr/local/scripts/catalina_rotate.sh /opt/alfresco/tomcat > /dev/null 2>&1
59 23 * * * /usr/local/scripts/all_logs_compress.sh /opt/alfresco/tomcat > /dev/null 2>&1

# get a 5.2.5 (yes, trust me) ctl.sh script
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/ctl.sh -P $CATALINA_HOME/scripts/
chown alfresco. $CATALINA_HOME/scripts/ctl.sh
chmod +x $CATALINA_HOME/scripts/ctl.sh

# make alfresco user able to start, stop, restart and check the
# status of alfresco.service, activemq.service and solr.service
vim /etc/sudoers.d/alfresco_sudoers
---
# Allows members of the alfresco group to start and stop alfresco service
%alfresco ALL= NOPASSWD: /bin/systemctl start   alfresco
%alfresco ALL= NOPASSWD: /bin/systemctl stop    alfresco
%alfresco ALL= NOPASSWD: /bin/systemctl restart alfresco
%alfresco ALL= NOPASSWD: /bin/systemctl status  alfresco

# Allows members of the alfresco group to start and stop alfresco service
%alfresco ALL= NOPASSWD: /bin/systemctl start   activemq
%alfresco ALL= NOPASSWD: /bin/systemctl stop    activemq
%alfresco ALL= NOPASSWD: /bin/systemctl restart activemq
%alfresco ALL= NOPASSWD: /bin/systemctl status  activemq

# Allows members of the alfresco group to start and stop solr service
%alfresco ALL= NOPASSWD: /bin/systemctl start   solr
%alfresco ALL= NOPASSWD: /bin/systemctl stop    solr
%alfresco ALL= NOPASSWD: /bin/systemctl restart solr
%alfresco ALL= NOPASSWD: /bin/systemctl status  solr
---


# JDBC driver not needed in case of Community, needed in case of Enterprise:
# before the command, do you use PostgreSQL?
mv $ALFRESCO_HOME/web-server/lib/* $CATALINA_HOME/lib/

# if Postgres is the DB and the Postgres connector is missing 
# put a Tomcat supported version of PostegreSQL JDBC in $CATALINA_HOME/lib
# too old or too new might not work as expected, have a look at:
# https://docs.alfresco.com/6.0/concepts/supported-platforms-ACS.html
wget https://jdbc.postgresql.org/download/postgresql-42.2.5.jar -P $CATALINA_HOME/lib/

# alfresco.xml and share.xml MUST be present in the destination folder
cp $ALFRESCO_HOME/web-server/conf/Catalina/localhost/*.xml $CATALINA_HOME/conf/Catalina/localhost/


# modify $CATALINA_HOME/conf/catalina.properties :
sed -i.ORIG 's#shared.loader\=#shared.loader=${catalina.base}/shared/classes,${catalina.base}/shared/lib/*.jar#g' $CATALINA_HOME/conf/catalina.properties


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
# it is a good idea to have a look at this file in a production server
# if you have one
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
index.subsystem.name=solr6
solr.host=localhost
solr.port=8983
solr.secureComms=none
solr.backup.alfresco.cronExpression=0 0 2 * * ?
solr.backup.alfresco.remoteBackupLocation=/ecm/data/solr6Backup/alfresco
solr.backup.archive.cronExpression=15 0 2 * * ?
solr.backup.archive.remoteBackupLocation=/ecm/data/solr6Backup/archive
solr.backup.alfresco.numberToKeep=1
solr.backup.archive.numberToKeep=1

alfresco.rmi.services.host=0.0.0.0
# Safety options: set to "true" only when the setup is
# really ready and everything is properly backed up
db.schema.update=false
server.allowWrite=false


# edit $CATALINA_HOME/conf/server.xml so that:
 <Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443"
               URIEncoding="UTF-8"
               maxHttpHeaderSize="32768" />
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
vim $CATALINA_HOME/conf/context.xml
# and comment that Valve below
<!--
<Valve className="org.apache.catalina.authenticator.SSLAuthenticator" securePagesWithPragma="false" />
-->

# if Tomcat >= 8.0
vim $CATALINA_HOME/webapps/manager/META-INF/context.xml
# and comment the Valve this way
<!--
  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
-->



# install AMPs 
MMT install $ALFRESCO_HOME/amps/       $CATALINA_HOME/webapps/alfresco/ -nobackup
MMT install $ALFRESCO_HOME/amps_share/ $CATALINA_HOME/webapps/share/    -nobackup


# define logging for Alfresco and solr web apps:
cd $CATALINA_HOME/webapps/alfresco/WEB-INF/classes/
sed -i.ORIG 's#log4j.appender.File.File=alfresco.log#log4j.appender.File.File=${catalina.base}/logs/alfresco.log#g' log4j.properties
# read the documentation about custom-log4j.properties
cp -a log4j.properties $CATALINA_HOME/shared/classes/alfresco/extension/custom-log4j.properties
cd $CATALINA_HOME/webapps/share/WEB-INF/classes/
sed -i.ORIG 's#log4j.appender.File.File=share.log#log4j.appender.File.File=${catalina.base}/logs/share.log#g' log4j.properties




######### LibreOffice install #########


# download and extract LibreOffice for your platform
# http://docs.alfresco.com/6.2/concepts/supported-platforms-ACS.html
cd /root/work/
wget https://downloadarchive.documentfoundation.org/libreoffice/old/6.3.5.2/rpm/x86_64/LibreOffice_6.3.5.2_Linux_x86-64_rpm.tar.gz
tar -xzf LibreOffice_6.3.5.2_Linux_x86-64_rpm.tar.gz

# CD to the RPMS directory and remove any files with gnome , kde in the filename.
cd LibreOffice_6.1.6.3_Linux_x86-64_rpm/RPMS/
rm -rf *gnome* *kde* *freedesktop-menus*
# yum install -y 
yum install *.rpm -y

# Ignore any desktop update not found error messages.  You can remove the rpm files after installation

# LibreOffice will be probably installed in /opt/LibreOffice6.1 :
option A - make a symlink: ln -sf /opt/libreoffice6.1/ $ALFRESCO_HOME/libreoffice
option B - move it       : mv /opt/libreoffice6.1/ $ALFRESCO_HOME/libreoffice

# create the scripts folder and put a .sh in it:
mkdir $ALFRESCO_HOME/libreoffice/scripts
cd $ALFRESCO_HOME/libreoffice/scripts
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/libreoffice_ctl.sh
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/libreoffice_check.sh
chmod u+x *


# Libraries : check first IF this ones are missing
rpm -q libXinerama     \
       mesa-libGLU     \
       fontconfig      \
       libICE          \
       libSM           \
       libXrender      \
       libXext         \
       libgl1-mesa-glx \
       cups-libs       \
       cairo           ;
       
# in my case, I had to install:
yum install libXinerama mesa-libGLU fontconfig cups-libs cairo -y ;

# SUSE
# https://www.suse.com/LinuxPackages/packageRouter.jsp?product=server&version=12&service_pack=&architecture=x86_64&package_name=index_all
zypper install libXinerama1 libGLU fontconfig libICE6 libSM6 libXrender1 libXext6 cups-libs libcairo2 Mesa-libGL1 libcairo-gobject2

# jodConverter.maxTasksPerProcess=100
# Do not include a slash (/) at the end of the path:
# jodconverter.officeHome=/opt/alfresco/LibreOffice
vim $CATALINA_HOME/shared/classes/alfresco-global.properties


######### ImageMagick install #########
# EPEL is your friend, so:
yum install -y epel-release

# ImageMagick installation process is not that clear but try to get a .rpm for it and force the installation
# probably the installer will complain but there are high chances that will get a working installation... for
# Alfresco at least (in the end just "convert" is used).

# CentOS 7 / RHEL 7 - NOT CentOS nor RHEL 8 (unless you want to get mad with libs dependencies
cd /root/work/
wget https://imagemagick.org/download/linux/CentOS/x86_64/ImageMagick-libs-7.0.10-30.x86_64.rpm
wget https://imagemagick.org/download/linux/CentOS/x86_64/ImageMagick-7.0.10-30.x86_64.rpm
yum localinstall -y ImageMagick-libs-7.0.10-30.x86_64.rpm ImageMagick-7.0.10-30.x86_64.rpm

#SUSE
zypper addrepo https://download.opensuse.org/repositories/graphics/SLE_12_SP3_Backports/graphics.repo
zypper refresh
zypper install ImageMagick

# unnecessary on Centos 7 :
#wget https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz

# the key point is that we WILL NOT have a root directory so in alfresco-global.properties define
# an empty root folder (see the provided file):

img.root=
img.dyn=/usr/lib64
img.exe=/usr/bin/convert
# Check the path is correct
img.coders=/usr/lib64/ImageMagick-7.0.10/modules-Q16HDRI/coders
# Check the path is correct
img.config=/etc/ImageMagick-7

######### ImageMagick install #########

######### PDF renderer install #########
cd $ALFRESCO_HOME/alfresco-pdf-renderer/
tar xfzv alfresco-pdf-renderer-1.1-linux.tgz



######### Solr - same host - no SSL so far #########
# references: http://docs.alfresco.com/6.1/tasks/solr6-install-withoutSSL.html
#             http://docs.alfresco.com/6.1/concepts/external-properties-solr6.html
wget https://process.alfresco.com/r/amazon/edl/?p=SearchServices/1.4.2&f=alfresco-search-services-1.4.2.zip
unzip alfresco-search-services-1.4.2.zip -d alfresco-search-services-1.4.2
mv alfresco-search-services-1.4.2 /opt/
ln -s /opt/alfresco-search-services-1.4.2 /opt/solr
vim /opt/solr/solrhome/conf/shared.properties

# uncomment ONLY if you have plenty of RAM otherwise you'll get an OutOfMemoryError almost always on solr
#alfresco.suggestable.property.0={http://www.alfresco.org/model/content/1.0}name
#alfresco.suggestable.property.1={http://www.alfresco.org/model/content/1.0}title 
#alfresco.suggestable.property.2={http://www.alfresco.org/model/content/1.0}description 
#alfresco.suggestable.property.3={http://www.alfresco.org/model/content/1.0}content

# https://docs.alfresco.com/search-enterprise/tasks/solr-install.html
# "If you use several languages across your organization, you must enable cross-language search support in all fields."
alfresco.cross.locale.datatype.0={http://www.alfresco.org/model/dictionary/1.0}text
alfresco.cross.locale.datatype.1={http://www.alfresco.org/model/dictionary/1.0}content
alfresco.cross.locale.datatype.2={http://www.alfresco.org/model/dictionary/1.0}mltext

# modify ONLY if you want to change Solr context (not even ASPI do this).
solr.baseurl=/solr -> solr.baseurl=/opt/solr/solr

# set SOLAR_HOME for solr
vim /opt/solr/solr.in.sh
# uncomment SOLR_HOME and add the path
SOLR_HOME=/opt/solr/solrhome
# and maybe change Java memory
SOLR_JAVA_MEM="-Xms2g -Xmx2g"


# start Solr , first time only command
/opt/solr/solr/bin/solr start -a "-Dcreate.alfresco.defaults=alfresco,archive"

# modify: alfresco.secureComms=https
# to:     alfresco.secureComms=none     
vim $SOLR_HOME/alfresco/conf/solrcore.properties
vim $SOLR_HOME/archive/conf/solrcore.properties
# and restart Solr


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



vim $CATALINA_HOME/conf/server.xml
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


vim $CATALINA_HOME/shared/classes/alfresco-global.properties
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

vim /opt/solr/solr.in.sh
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
vim $SOLR_HOME/alfresco/conf/solrcore.properties
vim $SOLR_HOME/archive/conf/solrcore.properties

# restart solr and test you can reach its website.





######### Apache reverse proxy - AJP #########
vim /opt/alfresco/tomcat/shared/classes/alfresco-global.properties

alfresco.host=alfresco.tst.lcl
alfresco.port=443
[...]
share.host=alfresco.tst.lcl
share.port=443


vim /opt/alfresco/tomcat/conf/server.xml

<Connector port="8009" protocol="AJP/1.3" redirectPort="8443" tomcatAuthentication="false" />


# then copy the previously generated key and certs to the Apache machine and edit:
vim /etc/httpd/conf.d/ssl.conf

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
vim /etc/httpd/conf.d/mod_proxy_ajp.conf

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



wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/solr.service -P /etc/systemd/system/
wget https://raw.githubusercontent.com/papinifrancesco/Alfresco/master/alfresco.service -P /etc/systemd/system/
systemctl daemon-reload

