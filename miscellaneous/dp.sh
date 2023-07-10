# diff properties files
#!/bin/bash

sed '/^#/ d' < "$1" > /tmp/temp1.txt
sed '/^#/ d' < "$2" > /tmp/temp2.txt

sort /tmp/temp1.txt
sort /tmp/temp2.txt

diff -y -W220 /tmp/temp1.txt /tmp/temp2.txt

rm -f /tmp/temp1.txt /tmp/temp2.txt
