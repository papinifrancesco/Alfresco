#!/bin/bash
# libreoffice_check.sh should be called by alfresco.sh , put a line below LIBREOFFICE_SCRIPT :
# LIBREOFFICE_CHECK=$INSTALLDIR/libreoffice/scripts/libreoffice_check.sh

pgrep -fl office -P 1 > /dev/null 2>&1
#[ $? -eq 0 ] && echo "orphan LibreOffice process detected" || echo "no orphan LibreOffice process detected"
pkill -9 -f office -P 1 > /dev/null 2>&1
[ $? -eq 0 ] && echo "orphan LibreOffice process killed"
