### what has modified in Alfresco ? ####
clear
find /opt/alfresco/ -type f -regextype posix-extended -iregex '.*.(js|jsp|orig|properties|sh|xml)' |\
grep -E -v  '/temp/|[0-9].xml' > /root/file_list.txt
while read -r line; do stat -c '%Y %n' "$line"; done < /root/file_list.txt | sort -n | cut -d ' ' -f2
