#reference: http://tomcat.apache.org/native-doc/

#######################################################################
#NAME="SLES_SAP"
#VERSION="12-SP1"
#VERSION_ID="12.1.0.1"
#PRETTY_NAME="SUSE Linux Enterprise Server for SAP Applications 12 SP1"

zypper install libapr1-devel
zypper install libopenssl-devel
#######################################################################


cd /root/work/
wget https://archive.apache.org/dist/tomcat/tomcat-connectors/native/1.2.23/source/tomcat-native-1.2.23-src.tar.gz
tar xvfz tomcat-native-1.2.23-src.tar.gz
cd tomcat-native-1.2.23-src/native

./configure --with-apr=/usr/bin/apr-1-config \
            --with-java-home=/ecm/software/alfresco-content-services-6.2.0/java \
            --with-ssl=/usr/include/openssl \
            --prefix=/ecm/software/alfresco-content-services-6.2.0/tomcat ;

make && make install
