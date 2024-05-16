#!/bin/bash

sed -e '/^#/ d' -e '/^$/ d' < "$1" > /tmp/temp1.txt
sed -e '/^#/ d' -e '/^$/ d' < "$2" > /tmp/temp2.txt

sort /tmp/temp1.txt > /tmp/temp3.txt
sort /tmp/temp2.txt > /tmp/temp4.txt

diff -y -W220 /tmp/temp3.txt /tmp/temp4.txt

rm -f /tmp/temp1.txt /tmp/temp2.txt /tmp/temp3.txt /tmp/temp4.txt
