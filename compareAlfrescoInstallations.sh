##### do it for both /opt/alfresco /opt/solr #####
ODIR=/opt/alfresco-one-5.1.2
NDIR=/opt/alfresco-5.2.4
FILTER="*BAK*|\.a|\.h|\.bat|\.bau|\.bin|\.cfg|\.class|\.css|\.dat|\.dtd|\.desktop|\.dic|\examples|\.gif|\.glsl|\.gz|\.html|\.jar|\.java|\.la|LibreLogo|\.log|\.m4|\.mdl|\.mod|\.pc|\.pl|\.pdf|\.png|\.py|\.rdb|\.sample|\.so|\.sdg|\.str|\.svg|\.thm|\.ttf|\.ui|templates|terminfo|\.txt|\.war|\.xba|\.xcd|\.xlb|\.xsl|\.zip"
reset; reset; 
diff -qrN $ODIR $NDIR | \
grep -E -v  '$FILTER' | \
sort ;



# different approach, maybe more clean

reset;reset;
diff -qrN $ODIR $NDIR |
grep -E  '\.ORIG|\.pri|\.properties|\.pub|\.sh|\.xml' |
grep -E -v '\.js|\.jar|\.jsp|\.class|\.war|\.gz|\.swf|\.java|\.ico|\.woff|\.svg|\.as|\.dvm|\.dim|\.tip|\.fdt|\.fdx|\.fnm|\.nvd|\.nvm|\.psd|/logs/' |
grep -E -v '\.css|\.gif|\.jpg|\.html|\.png|\.sample|\.BAK|dashlets|site-webscripts|alfresco/messages|/cmm/|/documentlibrary/|/components/|example|maven\.org' |
grep -E -v 'LibreLogo|google/docs|/soffice.cfg/|/liblangtag/|/nlpsolver/|/templates/|/libreoffice/share/extensions/|/libreoffice/share/wizards/' |
grep -E -v '/alfrescoModels/|/js/lib/|/js/scripts/|/host-manager/|/manager/|/java/|/ImageMagick|/libreoffice/help/|/model/|/content/|/skins/' |
sort;

