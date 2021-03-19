### The idea is: I have a working installation in a test machine and I want to clone ###
### that installation to the production machine. Probably most of the settings will  ###
### be OK so we can rsync test to production but we don't want to clone the content  ###
### stores , the Solr indexes nor the temporary files                                ###

#!/bin/bash

SOURCE=/opt/alfresco/

DESTINATION=user@host:/opt/

EXCLUSIONS=clone_alfresco_exclusions.txt

rsync -avz --exclude-from "$EXCLUSIONS" "$SOURCE" "$DESTINATION"
