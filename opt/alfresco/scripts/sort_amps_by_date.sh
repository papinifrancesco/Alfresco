#!/bin/bash

# usage example:
# sort_amps_by_date.sh /opt/alfresco-content-services-6.2.0
# sort_amps_by_date.sh /opt/alfresco-content-services-7.0.1.0

ALF=/opt/alfresco
[ -d "$1" ] && ALF=$1
ALFWEBAPPS=${2:-$ALF/tomcat/webapps}
[ -n "$3" ] && PRE=$3
export ALF_HOME=$ALF
export CATALINA_HOME=$ALF_HOME/tomcat
#. "$CATALINA_HOME"/bin/setenv.sh
export PATH=$JAVA_HOME/bin:$PATH
MMT='/opt/alfresco/java/bin/java -jar /opt/alfresco/bin/alfresco-mmt.jar'

function list_amps_by_date () {
          echo
          echo "$1 webapp"
          $MMT list "$ALFWEBAPPS"/"${PRE}""$1" |\
          grep -Ew "^Module|Version|Install Date" |\
          awk '/^Module/{printf $2" "}/Version/{printf "("$3") "}/Install Date/{print $0}' |\
          awk '{printf $1" "$2" ";cmd="date -d \""$(NF-5)" "$(NF-4)" "$(NF-3)" "$(NF-2)" "$(NF-1)" "$NF"\" +%s"; system(cmd)}' |\
          sort -k3 -n |\
          awk '{printf $1" "$2": ";system("date -d @"$3" +%F_%T")}' |\
          column -t -s': _' ;
          echo
}

list_amps_by_date alfresco

list_amps_by_date share
