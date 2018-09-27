reset
# copy the tomcat folder into AlfrescoBaseDir first!
export AlfrescoBaseDir="/home/fra/Downloads/alfresco-content-services-community-distribution-6.0.7-ga-TAI"

export AlfrescoServer="192.168.122.44"

export AlfrescoHome="/opt/alfresco-content-services"

export CATALINA_HOME="/opt/alfresco-content-services/tomcat"

scp -r $AlfrescoBaseDir $AlfrescoServer:$AlfrescoHome

ssh $AlfrescoServer md $CATALINA_HOME/webapps

# create these folders!
ssh $AlfrescoServer "md $AlfrscoBaseDir/modules
                     md $AlfrscoBaseDir/modules/platform
                     md $AlfrscoBaseDir/modules/share"

scp $AlfrescoBaseDir/web-server/webapps/*.war $AlfrescoServer:$CATALINA_HOME/webapps/

scp -r $AlfrescoBaseDir/web-server/shared/classes $AlfrescoServer:$CATALINA_HOME/shared/

# JDBC driver not needed:
# scp -r $AlfrescoBaseDir/web-server/lib $AlfrescoServer:$CATALINA_HOME/lib

# alfresco.xml and share.xml MUST be present in the destination folder
scp $AlfrescoBaseDir/web-server/conf/Catalina/localhost/*.xml $AlfrescoServer:$CATALINA_HOME/conf

# put an up to date PostegreSQL JDBC in $CATALINA_HOME/lib
# check that your version of the JDBC is supported by your version of Tomcat
scp postgresql-42.2.5.jar $AlfrescoServer:$CATALINA_HOME/lib

# check that $CATALINA_HOME/conf/catalina.properties has:
shared.loader=${catalina.base}/shared/classes


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




# to stop Tomcat, ALWAYS use [...]/shutdown.sh 300 -force

# remember the setEnv.sh


# Database and user setup
# http://docs.alfresco.com/6.0/concepts/mariadb-config.html
# mysql -u root
#
# DROP DATABASE `alfresco`;
# CREATE DATABASE `alfresco` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */;
# DA FARE : COLLATE utf8_bin , controllare
# CREATE USER 'alfresco'@'%' IDENTIFIED BY 'alfresco';
# GRANT ALL PRIVILEGES ON alfresco.* TO 'alfresco'@'%';	


# PostgreSQL , psql
CREATE USER alfresco WITH PASSWORD 'admin';
CREATE DATABASE alfresco OWNER alfresco ENCODING 'utf8';
GRANT ALL PRIVILEGES ON DATABASE alfresco TO alfresco;
