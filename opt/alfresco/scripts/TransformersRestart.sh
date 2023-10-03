#!/bin/bash
# should be put in /opt/alfresco/scripts
# crontab -e -u alfresco
# 50 23 * * * /opt/alfresco/scripts/TransformersRestart.sh
# we need to restart these services because the log files
# are locked so a cat /dev/null > file is useless

sudo systemctl stop alfresco-transform-router

sudo systemctl stop alfresco-transform-core

sleep 5

sudo systemctl start alfresco-transform-core

sleep 10

sudo systemctl start alfresco-transform-router
