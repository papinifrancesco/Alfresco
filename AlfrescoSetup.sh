reset
# copy the tomcat folder into AlfrescoBaseDir first!
export AlfrescoBaseDir="/home/fra/Downloads/alfresco-content-services-community-distribution-6.0.7-ga-TAI"

export AlfrescoServer="192.168.122.44"

export AlfrescoHome="/opt/alfresco-content-services"

export CATALINA_HOME="/opt/alfresco-content-services/tomcat"

scp -r $AlfrescoBaseDir $AlfrescoServer:$AlfrescoHome


# create these folders!
ssh $AlfrescoServer "mkdir $AlfrescoHome/modules
                     mkdir $AlfrescoHome/modules/platform
                     mkdir $AlfrescoHome/modules/share
                     mkdir $CATALINA_HOME/shared
                     mkdir $CATALINA_HOME/webapps"

scp $AlfrescoBaseDir/web-server/webapps/*.war $AlfrescoServer:$CATALINA_HOME/webapps/

########################scp -r $AlfrescoBaseDir/web-server/shared/classes $AlfrescoServer:$CATALINA_HOME/shared/

# JDBC driver not needed:
# scp -r $AlfrescoBaseDir/web-server/lib $AlfrescoServer:$CATALINA_HOME/lib

# alfresco.xml and share.xml MUST be present in the destination folder
scp $AlfrescoBaseDir/web-server/conf/Catalina/localhost/*.xml $AlfrescoServer:$CATALINA_HOME/conf

# put an up to date PostegreSQL JDBC in $CATALINA_HOME/lib
# check that your version of the JDBC is supported by your version of Tomcat
scp postgresql-42.2.5.jar $AlfrescoServer:$CATALINA_HOME/lib

# check that $CATALINA_HOME/conf/catalina.properties has:
shared.loader=${catalina.base}/shared/classes

# check that $CATALINA_HOME/bin/setenv.sh exist and correct its contents:
export CATALINA_PID=/opt/alfresco-content-services/tomcat/temp/catalina.pid
export JAVA_HOME=/usr/java/jdk1.8.0_181-amd64


# edit $CATALINA_HOME/shared/classes/alfresco-global.properties and check:
dir.root=/opt/alfresco-content-services/alf_data
dir.keystore=${dir.root}/keystore
db.username=alfresco
db.password=alfresco
db.schema.update=true
db.driver=org.postgresql.Driver
db.url=jdbc:postgresql://192.168.122.45:5432/alfresco
alfresco.context=alfresco
alfresco.host=alfresco6
alfresco.port=8080
alfresco.protocol=http
share.context=share
share.host=alfresco6
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
unzip $CATALINA_HOME/webapps/alfresco.war
unzip $CATALINA_HOME/webapps/share.war
unzip $CATALINA_HOME/webapps/ROOT.war


# install AMPs , by default only $AlfrescoHome/amps/alfresco-share-services.amp
$AlfrescoHome/bin/alfresco-mmt.jar install $AlfrescoHome/amps/alfresco-share-services.amp $CATALINA_HOME/webapps/alfresco.war

# define logging for the web apps:
# $CATALINA_HOME/webapps/alfresco/WEB-INF/classes/log4j.properties
# $CATALINA_HOME/webapps/share/WEB-INF/classes/log4j.properties
log4j.appender.File.File=${catalina.base}/logs/alfresco.log

# to stop Tomcat, ALWAYS use [...]/shutdown.sh 300 -force



# Database and user setup
# http://docs.alfresco.com/6.0/concepts/mariadb-config.html
# mysql -u root
#
# DROP DATABASE `alfresco`;
# CREATE DATABASE `alfresco` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */;
# DA FARE : COLLATE utf8_bin , controllare
# CREATE USER 'alfresco'@'%' IDENTIFIED BY 'alfresco';
# GRANT ALL PRIVILEGES ON alfresco.* TO 'alfresco'@'%';	


# on the DB server: PostgreSQL , psql
psql -U postgres
CREATE USER alfresco WITH PASSWORD 'alfresco';
CREATE DATABASE alfresco OWNER alfresco ENCODING 'utf8';
GRANT ALL PRIVILEGES ON DATABASE alfresco TO alfresco;
