#!/bin/bash
# ---------------------------------
# Script to clean Tomcat temp files
# ---------------------------------
# should be in:
# /opt/alfresco/bin/
# and /opt/alfresco/alfresco.sh should call it
echo "Cleaning temporary Alfresco files from Tomcat..."
[ $# -ne 1 ] && echo "Usage: `basename $0` /path/to/tomcat_dir" && exit -1
INSTALLDIR=$1
$INSTALLDIR/tomcat/scripts/ctl.sh status | grep "not running" > /dev/null 2>&1
[ $? -ne 0 ] && echo "Tomcat running, no action!" && exit -1 || echo "removing..."
cd $INSTALLDIR
find tomcat/temp/ -mindepth 1 -maxdepth 1 -path tomcat/temp/safeToDelete.tmp -prune -o -type f -exec rm -f {} \;
rm -rf tomcat/temp/Alfresco*
rm -rf tomcat/work/Catalina
touch tomcat/{temp,work}/.cleaned
