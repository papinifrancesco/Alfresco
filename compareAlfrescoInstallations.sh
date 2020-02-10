# cautious approach: since we're not completely sure about what   #
# we really want, it is better to just exclude what we don't want #
##### do it for both /opt/alfresco /opt/solr #####
#ODIR=/ecm/software/alfresco/
ODIR=/ecm/software/share/
#NDIR=/ecm/software/alfresco-content-services-6.2.0/
NDIR=/ecm/software/share-6.2.0/
FILTER_DIRS="webapps\/manager|webapps\/host-manager|tomcat\/logs|tomcat\/work|tomcat\/temp|libreoffice\/program|libreoffice/share"
FILTER_EXTENSIONS="\.template|\.sample|\.ico|\.run|\.dll|\.1|\.ORIG|\.js|\.xsd|\.MF|\.a|\.h|\.bat|\.bau|\.bin|\.cfg|\.class|\.css|\.dat|\.dtd|\.desktop|\.dic|\.gif|\.glsl|\.gz|\.html|\.jar|\.java|\.la|\.log|\.m4|\.mdl|\.mod|\.pc|\.pl|\.pdf|\.png|\.py|\.rdb|\.sample|\.so|\.sdg|\.str|\.svg|\.thm|\.ttf|\.ui|\.txt|\.war|\.xba|\.xcd|\.xlb|\.xsl|\.zip"
FILTER_STRINGS="googledocs|*BAK*|CONTRIBUTING|RELEASE-NOTES|README|NOTICE|LICENSE|CREDITS|VERSIONS|examples|java|LibreLogo|templates|terminfo"
FILTER_EXPRESSIONS="..\.properties"
FILTER="$FILTER_DIRS|$FILTER_EXTENSIONS|$FILTER_STRINGS|$FILTER_EXPRESSIONS"
clear; clear;
diff -qr $ODIR $NDIR | \
grep -E -v $FILTER | \
sort ;
