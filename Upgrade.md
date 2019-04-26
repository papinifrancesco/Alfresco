If you need to install A524 on a machine where A51x is running, install, with typical options but under /opt/alfresco, A524 on a dedicated (maybe temporary) VM

Copy the whole Alfresco tree from the VM to the target machine

Why? Because that way the installer will generate all of the files referring to /opt/alfresco

It is not good to realise later that your Alfresco tree contains lots of /somedir/alfresco-5.2.4 pointers


A list of notes to perform an Alfresco upgrade, review:

http://docs.alfresco.com/6.0/tasks/upgrade-process.html






Remember to check the DB driver (a .jar probably), from a version to another the file might not be the same: for example in /opt/alfresco/tomcat/lib/ we may have ojdbc6.jar but the Alfresco version needs ojdbc7.jar



**ALWAYS** make a copy of a file you're going to modify so it'll be easy later on to understand what you did, example:
```
cp alfresco-global.properties alfresco-global.properties.ORIG
```



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


Also, using **vim** or others, check for the context inside these files:

```
:%s/8080:\/alfresco/8080:\DAFSVIalfresco/,gc    

bin/clean_tomcat.sh
solr4/archive-SpacesStore/conf/solrcore.properties
solr4/workspace-SpacesStore/conf/solrcore.properties
tomcat/shared/classes/alfresco/web-extension/share-config-custom.xml
tomcat/shared/classes/alfresco-global.properties    
tomcat/webapps/ROOT/index.jsp
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
common/lib/ImageMagick-x.x.x/config-Q16/policy.xml
libreoffice/scripts/libreoffice_check.sh
solr4/archive-SpacesStore/conf/solrcore.properties
solr4/workspace-SpacesStore/conf/solrcore.properties
solr4/context.xml
tomcat/shared/classes/alfresco-global.properties
tomcat/scripts/ctl.sh
tomcat/bin/setenv.sh
tomcat/conf/context.xml
tomcat/conf/server.xml
tomcat/conf/tomcat-users.xml
tomcat/shared/classes/alfresco/web-extension/custom-slingshot-application-context.xml
tomcat/shared/classes/alfresco/web-extension/share-config-custom.xml
tomcat/shared/classes/alfresco/extension/subsystems/Authentication/ldap-ad/ad1/ldap-ad-authentication.properties
tomcat/shared/classes/tnsnames.ora
tomcat/shared/classes/alfresco/extension/custom-log4j.properties
```


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

 

Clean, if needed, both "temp" and "work"
```
rm -rf /opt/alfresco/tomcat/work/*
rm -rf /opt/alfresco/tomcat/temp/*
```


Give the appropriate permissions to a user, don't run things with root:
`chown -R dft.dftgrp /prd/dft/alfresco-5.2.4`