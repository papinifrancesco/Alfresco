# First of all, I assume you've read:
# https://github.com/papinifrancesco/Alfresco7001/blob/main/AlfrescoSetup7001.sh
# and you made it in having a completely working installation.

# Then, study :
# https://docs.alfresco.com/content-services/community/upgrade/
# https://docs.alfresco.com/content-services/6.0/upgrade/
# up to:
# https://docs.alfresco.com/content-services/latest/upgrade/

# After all that, let's have a look at my notes.


# ALWAYS make a copy of a file you're going to modify so it'll be easy later on
# (for you and your colleagues) to understand had been done, example:
cp -a alfresco-global.properties alfresco-global.properties.ORIG
# or
cp -a alfresco-global.properties alfresco-global.properties.20210428_FL
# where _FL stands for initial of the First name and initial of the Last name


# create one symlink to the old alfresco installation
ln -s alfresco-6.2.1 ACS6
# create one symlink to the new alfresco installation
ln -s alfresco-content-services.7.0.0.1 ACS7
# why this? When diffing the two installations later on, it comes in handy to have:
# a) the least differences in the paths
# b) shorter paths
# example, is it better this:
diff -qr alfresco-content-services-6.2.1 alfresco-content-services-7.0.0.1
[...]
Only in alfresco-content-services-7.0.0.1/amps: aos
Only in alfresco-content-services-6.2.1/amps_share: alfresco-googledrive-share-3.2.0.amp
# or this:
diff -qr ACS6 ACS7
[...]
Only in ACS7/amps: aos
Only in ACS6/amps_share: alfresco-googledrive-share-3.2.0.amp




# If you need to install A52x on a machine where A51x is running, install, with typical options but under /opt/alfresco,
# A52x on a dedicated (maybe temporary) VM
# Copy the whole Alfresco tree from the VM to the target machine because
# that way the installer will generate all of the files referring to /opt/alfresco
# It is not good to realise later that your Alfresco tree contains lots of /somedir/alfresco-5.2.x pointers


# check the DB driver (a .jar probably)
# from a version to another the file might not be the same:
# for example in /opt/alfresco/tomcat/lib/ we may have ojdbc6.jar but the new Alfresco version needs ojdbc7.jar


# check alfresco-global.properties first so you can have a picture of what you have







Although most customers leave the default "alfresco" and "share" contexts, some of them wants a customized one, e.g. "SMTHalfresco" , "SMTHshare" , refer to:

https://docs.alfresco.com/6.0/tasks/deploy-contextpath.html


remember to change, for example:

```
/opt/alfresco/tomcat/webapps/
                            alfresco.war -> DAFSVIalfresco.war
                               alfresco/ -> DAFSVIalfresco/
```


```
/opt/alfresco/tomcat/conf/Catalina/localhost/
                                            alfresco.xml -> DAFSVIalfresco.xml
                                               share.xml -> DAFSVIshare.xml
```

```
/opt/alfresco/tomcat/webapps/share/js/alfresco.js
/opt/alfresco/tomcat/webapps/share/js/alfresco.min.js

from:
Alfresco.constants.PROXY_V1_URI = "/share/proxy" + Alfresco.constants.API_V1_BASE_URL;
to:
Alfresco.constants.PROXY_V1_URI = "/DAFSVIshare/proxy" + Alfresco.constants.API_V1_BASE_URL;
```



Also, using **vim** or others, check for the context inside these files:

```
:%s#DAFSVIalfresco#DAFalfresco#gc
:%s#DAFSVIshare#DAFshare#gc

bin/apply_amps.sh
bin/clean_tomcat.sh
solr4/archive-SpacesStore/conf/solrcore.properties
solr4/workspace-SpacesStore/conf/solrcore.properties
tomcat/shared/classes/alfresco-global.properties    

:%s#8080/DAFSVIalfresco#8080/DAFalfresco#gc
tomcat/shared/classes/alfresco/web-extension/share-config-custom.xml


:%s#alfrescoContextName = "DAFSVIalfresco";#alfrescoContextName = "DAFalfresco";#gc
tomcat/webapps/ROOT/index.jsp

:%s#<param-value>/DAFSVIalfresco/aos</param-value>#<param-value>/DAFalfresco/aos</param-value>#gc
tomcat/webapps/_vti_bin/WEB-INF/web.xml
```




Check which amps are installed, remember that AOS in 5.0 was NOT an .amp but a .jar

```
java/bin/java -jar /opt/alfresco/bin/alfresco-mmt.jar list /opt/alfresco/tomcat/webapps/DFTSVIalfresco
java/bin/java -jar /opt/alfresco/bin/alfresco-mmt.jar list /opt/alfresco/tomcat/webapps/DFTSVIshare
```



**diff** the configuration files from old installation (left) and new installation (right) , example:
```
ODIR=/opt/alfresco-5.1.2
NDIR=/opt/alfresco-5.2.4
AFILE=tomcat/shared/classes/alfresco-global.properties
diff $ODIR/$AFILE $NDIR/$AFILE
```

diff and check all of these files:
```
alfresco.sh
bin/apply_amps.sh
bin/clean_tomcat.sh
libreoffice/scripts/libreoffice_check.sh
solr4/archive-SpacesStore/conf/solrcore.properties
solr4/archive-SpacesStore/conf/solrconfig.xml
solr4/workspace-SpacesStore/conf/solrcore.properties
solr4/workspace-SpacesStore/conf/solrconfig.xml
solr4/context.xml
solr4/log4j-solr.properties
tomcat/shared/classes/alfresco-global.properties
tomcat/scripts/ctl.sh
tomcat/bin/setenv.sh
tomcat/conf/context.xml
tomcat/conf/server.xml (remember the packetSize and jvmRoute parameters)

tomcat/conf/tomcat-users.xml
tomcat/shared/classes/alfresco/web-extension/share-config-custom.xml
tomcat/shared/classes/alfresco/extension/license/CustomersName.lic.installed
tomcat/shared/classes/alfresco/extension/alfresco-jmxrmi.password
tomcat/shared/classes/alfresco/extension/production-log4j.properties
tomcat/shared/classes/alfresco/extension/subsystems/Authentication/ldap-ad/ad1/ldap-ad-authentication.properties
tomcat/shared/classes/tnsnames.ora
tomcat/shared/classes/alfresco/extension/custom-log4j.properties
tomcat/webapps/DAFalfresco/WEB-INF/classes/alfresco/content-services-context.xml (<bean id="extracter.RFC822" email extractor maybe OFF)
tomcat/scripts/jmxterm-1.0.1-uber.jar
tomcat/webapps/DigitalWorkspace/app.config.json
```


then check the modules: best praticeses say to use AMPs but that might not always be the case and modules could have been installed manually under:

tomcat/webapps/DAFalfresco/WEB-INF/classes/alfresco/module/

ask your colleagues which modules should be present and which not (remember to mv to .disabled) and update the list module.xml???? accordingly; delete from share-config-custom.xml the namespace of the excluded modules **<---- TO DO: explain better and make examples**

# Alfresco MUST be STOPPED!!!
copy your amps either to ./amps or ./amps_share then install them and take note of what happens

```
java -jar /opt/alfresco/bin/alfresco-mmt.jar install /opt/alfresco/amps/tech.amp /opt/alfresco/tomcat/webapps/DFTSVIalfresco/ -nobackup -force
java -jar /opt/alfresco/bin/alfresco-mmt.jar install /opt/alfresco/amps_share/tech-share.amp /opt/alfresco/tomcat/webapps/DFTSVIshare/ -nobackup -force
```

We could install the .amp to the .war as well with the same syntax, however check FIRST if a given amp needed further customization AFTER you deployed it, example: an xml file that need to be edited.
1. If you patch the folder first
1. Then you edit the xml file
1. Then you patch the .war

The folder will be misaligned with the .war and so the folder will be overwritten ...it means:
### you'll lose the xml file customisation you just did


If you want to install AOS manually (maybe an up to date version?)

http://docs.alfresco.com/aos1.1/tasks/aos-install.html 

remember that Alfresco must be stopped.

```
java -jar /opt/alfresco/bin/alfresco-mmt.jar install /pathToAmp/alfresco-aos-module-1.1.8.amp /opt/alfresco/tomcat/webapps/DFTSVIalfresco -nobackup
rm -rf /opt/alfresco/tomcat/webapps/_vti*
cp _vti_bin.war /opt/alfresco/tomcat/webapps/
unzip -d _vti_bin/ _vti_bin.war
```



If you're working with an Oracle DB copy **tnsnames.ora** in
`/opt/alfresco/tomcat/shared/classes/`

then edit setnv.sh to force the location of **tnsnames.ora** by adding:
`export TNS_ADMIN=/opt/alfresco/tomcat/shared/classes/`



Copy any eventual keystore from the old installation:
`cp $ODIR/tomcat/shared/classes/ldaps_keystore.jceks $NDIR/tomcat/shared/classes/`


Remember to force Alfresco to reload the license file as per:
http://docs.alfresco.com/6.1/tasks/at-adminconsole-license.html
```
cd /opt/alfresco/tomcat/shared/classes/alfresco/extension/license
mv AlfrescoLicense.lic.installed AlfrescoLicense.lic
```

Clean, if needed, both "temp" and "work"
```
rm -rf /opt/alfresco/tomcat/work/*
rm -rf /opt/alfresco/tomcat/temp/*
```


Give the appropriate permissions to a user, don't run things with root:
`chown -R dft.dftgrp /prd/dft/alfresco-5.2.4`
