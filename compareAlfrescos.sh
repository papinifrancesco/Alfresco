# 2020-07-03
# cautious approach: since we're not completely sure about what   #
# we really want, it is better to just exclude what we don't want #
##### do it for both /opt/alfresco /opt/solr #####
# usage compareAlfrescoInstallations.sh /ACSfolder1/ /ACSfolder2/
# tip: use real paths, not symlinks <- I need to further investigate this one

FILTER_DIRS="webapps\/manager\\b"
FILTER_DIRS="$FILTER_DIRS|webapps\/host-manager\\b"
FILTER_DIRS="$FILTER_DIRS|tomcat\/lib\\b"  # check manually for different database drivers
FILTER_DIRS="$FILTER_DIRS|tomcat\/logs\\b"
FILTER_DIRS="$FILTER_DIRS|tomcat\/temp\\b"
FILTER_DIRS="$FILTER_DIRS|tomcat\/work\\b"
FILTER_DIRS="$FILTER_DIRS|\/WEB-INF\/classes\/alfresco\/site-webscripts\\b"
FILTER_DIRS="$FILTER_DIRS|\/libreoffice\\b"
FILTER_DIRS="$FILTER_DIRS|\/java\\b"
FILTER_DIRS="$FILTER_DIRS|\/WEB-INF\/lib\\b" # no so sure about this one
FILTER_DIRS="$FILTER_DIRS|\/3rd-party\\b"
#FILTER_EXTENSIONS="\.bak\\b|\.template\\b|\.sample\\b|\.ico\\b|\.run\\b|\.dll\\b|\.1\\b|\.ORIG\\b|\.js\\b|\.xsd\\b|\.MF\\b|\.a\\b|\.h\\b|\.bat\\b|\.bau\\b|\.bin\\b|\.cfg\\b|\.class\\b|\.css\\b|\.dat\\b|\.dtd\\b|\.desktop\\b|\.dic\\b|\.gif\\b|\.glsl\\b|\.gz\\b|\.html\\b|\.jar\\b|\.java\\b|\.la\\b|\.log\\b|\.m4\\b|\.mdl\\b|\.mod\\b|\.pc\\b|\.pl\\b|\.pdf\\b|\.png\\b|\.py\\b|\.rdb\\b|\.sample\\b|\.so\\b|\.sdg\\b|\.str\\b|\.svg\\b|\.thm\\b|\.ttf\\b|\.ui\\b|\.txt\\b|\.war\\b|\.xba\\b|\.xcd\\b|\.xlb\\b|\.xsl\\b|\.zip\\b"
FILTER_EXTENSIONS="\.bin\\b|\.css\\b|\.gz\\b|\.install\\b|\.js\\b|\.sample\\b|\.ORIG\\b|\.bat\\b|\.war\\b|\.class\\b|\.svg\\b|\.xsd\\b|\.gif\\b"
#FILTER_EXTENSIONS="$FILTER_EXTENSIONS|"
FILTER_STRINGS="googledocs|*BAK*|CONTRIBUTING|RELEASE-NOTES|README|NOTICE|LICENSE|CREDITS|VERSIONS|examples|LibreLogo|templates|terminfo|cloud-folder|cloud-sync-management"
FILTER_STRINGS="$FILTER_STRINGS|user-cloud-auth"
FILTER_EXPRESSIONS="tomcat-i18n-??\.jar\\b|pom\.properties\\b|pom\.xml\\b|RUNNING\.txt\\b|MANIFEST\.MF\\b|BUILDING\.txt\\b|_[a-z]{2}\.properties\\b|_[a-z]{2}_[A-Z]{2}\.properties\\b"
FILTER_EXPRESSIONS="$FILTER_EXPRESSIONS|module\.properties\\b|\version\.properties\\b"
#FILTER_EXPRESSIONS="hfghsghsghdsgfvsdgfdsfg"
FILTER="$FILTER_DIRS|$FILTER_EXTENSIONS|$FILTER_STRINGS|$FILTER_EXPRESSIONS"
clear; clear;
diff -qr $1 $2 | \
grep -Ev "$FILTER" | \
sort ;
