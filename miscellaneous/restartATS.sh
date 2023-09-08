#!/bin/bash

systemctl stop alfresco-transform-router
pause 5
systemctl stop alfresco-transform-core
pause 5
systemctl stop alfresco-shared-file
pause 5
systemctl start alfresco-shared-file
pause 15
systemctl start alfresco-transform-core
pause 15
systemctl start alfresco-transform-router
