reset

export AlfrescoBaseDir="/home/fra/Downloads/alfresco-content-services-community-distribution-6.0.7-ga"

export AlfrescoServer="192.168.122.45"

export CATALINA_HOME="/opt/tomcat"



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






