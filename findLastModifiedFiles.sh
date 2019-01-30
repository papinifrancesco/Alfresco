clear
find /soft_install/alfresco-5.1.2/ -type f -regextype posix-extended -iregex '.*.(jsp|orig|properties|sh|xml)' | grep -v "/temp/" > /root/file_list.txt
while read -r line; do stat -c '%Y %n' "$line"; done < /root/file_list.txt | sort -n | cut -d ' ' -f2
