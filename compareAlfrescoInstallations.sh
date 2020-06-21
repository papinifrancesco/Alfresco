# As of 21/06/2020 still a work in progress, use it with caution
# cautious approach: since we're not completely sure about what   #
# we really want, it is better to just exclude what we don't want #
##### do it for both /opt/alfresco /opt/solr #####
# usage ./compareAlfrescoInstallations.sh /ACSfolder1/ /ACSfolder2/
#libreoffice\/program|libreoffice/share"

FILTER_DIRS="webapps\/manager"
FILTER_DIRS="$FILTER_DIRS|webapps\/host-manager"
FILTER_DIRS="$FILTER_DIRS|tomcat\/lib"  # check manually for different database drivers
FILTER_DIRS="$FILTER_DIRS|tomcat\/logs"
FILTER_DIRS="$FILTER_DIRS|tomcat\/temp"
FILTER_DIRS="$FILTER_DIRS|tomcat\/work"
FILTER_DIRS="$FILTER_DIRS|\/libreoffice\/"
FILTER_DIRS="$FILTER_DIRS|\/java\/"
FILTER_DIRS="$FILTER_DIRS|\/WEB-INF\/lib" # no so sure about this one
#FILTER_EXTENSIONS="\.ftm|\.bak|\.template|\.sample|\.ico|\.run|\.dll|\.1|\.ORIG|\.js|\.xsd|\.MF|\.a|\.h|\.bat|\.bau|\.bin|\.cfg|\.class|\.css|\.dat|\.dtd|\.desktop|\.dic|\.gif|\.glsl|\.gz|\.html|\.jar|\.java|\.la|\.log|\.m4|\.mdl|\.mod|\.pc|\.pl|\.pdf|\.png|\.py|\.rdb|\.sample|\.so|\.sdg|\.str|\.svg|\.thm|\.ttf|\.ui|\.txt|\.war|\.xba|\.xcd|\.xlb|\.xsl|\.zip"
#FILTER_STRINGS="googledocs|*BAK*|CONTRIBUTING|RELEASE-NOTES|README|NOTICE|LICENSE|CREDITS|VERSIONS|examples|java|LibreLogo|templates|terminfo"
FILTER_EXPRESSIONS="tomcat-i18n-??\.jar"
FILTER_EXPRESSIONS="$FILTER_EXPRESSIONS|tomcat-i18n-??\.jar"
#FILTER="$FILTER_DIRS|$FILTER_EXTENSIONS|$FILTER_STRINGS" #|$FILTER_EXPRESSIONS"
clear; clear;
diff -qr $1 $2 | \
grep -E -v '$FILTER_DIRS' | \
grep -E -v '$FILTER_EXPRESSIONS' | \
sort ;
