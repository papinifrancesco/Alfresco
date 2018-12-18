#!/bin/bash
# should be put in /usr/local/script

DATE_F=`date +%F`
TCAT_HOME=$1

if [ -s $TCAT_HOME/logs/catalina.out ]; then
cp -p $TCAT_HOME/logs/catalina.out $TCAT_HOME/logs/catalina_${DATE_F}.out
cat /dev/null > $TCAT_HOME/logs/catalina.out
gzip -9 $TCAT_HOME/logs/catalina_${DATE_F}.out
fi
