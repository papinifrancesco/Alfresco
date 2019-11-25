##### do it for both /opt/alfresco /opt/solr #####
ODIR=/opt/alfresco-one-5.1.2
NDIR=/opt/alfresco-5.2.4

reset; reset; 
diff -qrN $ODIR $NDIR | \
grep -E -v  '*BAK*|\.a|\.h|\.bat|\.bau|\.bin|\.cfg|\.class|\.css|\.dat|\.dtd|\.desktop|\.dic|\examples|\.gif|\.glsl|\.gz|\.html|\.jar|\.java|\.la|LibreLogo|\.log|\.m4|\.mdl|\.mod|\.pc|\.pl|\.pdf|\.png|\.py|\.rdb|\.sample|\.so|\.sdg|\.str|\.svg|\.thm|\.ttf|\.ui|templates|terminfo|\.txt|\.war|\.xba|\.xcd|\.xlb|\.xsl|\.zip' | \
sort ;



# different approach, maybe more clean
reset;reset; 
diff -qrN $ODIR $NDIR | 
grep -E -i  '\.js|\.jsp|\.ORIG|\.pri|\.properties|\.pub|\.sh|\.xml' |
grep -E -i -v '.BAK|dashlets|site-webscripts|alfresco/messages|/cmm/|/documentlibrary/|/components/|example|maven\.org' |
grep -E -i -v 'LibreLogo|google/docs|/soffice.cfg/|/liblangtag/' |
sort;
