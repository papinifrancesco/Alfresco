# references
#  generic:  https://tomcat.apache.org/native-doc/
#  specific: https://tomcat.apache.org/tomcat-8.5-doc/apr.html

#######################################################################
#NAME="SLES_SAP"
#VERSION="12-SP1"
#VERSION_ID="12.1.0.1"
#PRETTY_NAME="SUSE Linux Enterprise Server for SAP Applications 12 SP1"

zypper install libapr1-devel
zypper install libopenssl-devel
#######################################################################


cd /ecm/software/alfresco-content-services-6.2.0/tomcat/bin
tar xvfz tomcat-native-1.2.23-src.tar.gz
cd tomcat-native-1.2.23-src/native

./configure --with-apr=/usr/bin/apr-1-config \
            --with-java-home=/ecm/software/alfresco-content-services-6.2.0/java \
            --with-ssl=/usr/include/openssl \
            --prefix=/ecm/software/alfresco-content-services-6.2.0/tomcat ;

make && make install
