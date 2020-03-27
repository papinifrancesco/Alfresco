#!/bin/bash

SOURCE=/opt/alfresco-search-services-1.4.1/

DESTINATION=user@host:/opt/alfresco-search-services-1.4.1/

EXCLUSIONS=clone_solr_exclusions.txt

rsync -avz --exclude-from $EXCLUSIONS $SOURCE $DESTINATION
