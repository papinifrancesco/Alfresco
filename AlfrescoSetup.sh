reset
# copy the tomcat folder into AlfrescoBaseDir first!
export AlfrescoBaseDir="/home/fra/Downloads/alfresco-content-services-community-distribution-6.0.7-ga"

export AlfrescoServer="192.168.122.44"

export AlfrescoHome="/opt/alfresco-content-services"

export CATALINA_HOME="/opt/alfresco-content-services/tomcat"

scp -r $AlfrescoBaseDir $AlfrescoServer:$AlfrescoHome

ssh $AlfrescoServer md $CATALINA_HOME/webapps

scp $AlfrescoBaseDir/web-server/webapps/*.war $AlfrescoServer:$CATALINA_HOME/webapps/

scp -r $AlfrescoBaseDir/web-server/shared/classes $AlfrescoServer:$CATALINA_HOME/shared/

# JDBC driver not needed:
# scp -r $AlfrescoBaseDir/web-server/lib $AlfrescoServer:$CATALINA_HOME/lib


scp $AlfrescoBaseDir/web-server/conf/Catalina/localhost/*.xml $AlfrescoServer:$CATALINA_HOME/conf



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
