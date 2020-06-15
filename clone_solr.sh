#!/bin/bash

SOURCE=/opt/alfresco-search-services-1.4.2

DESTINATION=user@host:/tmp/

EXCLUSIONS=clone_solr_exclusions.txt

rsync -avz --exclude-from $EXCLUSIONS $SOURCE $DESTINATION
