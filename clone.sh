### The idea is: I have a working installation in a test machine and I want to clone ###
### that installation to the production machine. Probably most of the settings will  ###
### be OK so we can rsync test to production but we don't want to clone the content  ###
### stores , the Solr indexes nor the temporary files                                ###

SOURCE=/opt/alfresco
DESTINATION=alfresco-admin@54.32.2.2:/opt/

#rsync -navz --exclude-from='clone_exclusions.txt' $SOURCE $DESTINATION

rsync -navz --exclude={ 'contentstore/*'            , \ 
                        'contentstore.deleted/*'    , \
                        'logs/*'                    , \
                        'temp/*'                    , \
                        'work/*'                    , \
                                                    } ;
