#!/bin/bash

pgrep -fl office -P 1 > /dev/null 2>&1
#[ $? -eq 0 ] && echo "orphan LibreOffice process detected" || echo "no orphan LibreOffice process detected"
pkill -9 -f office -P 1 > /dev/null 2>&1
[ $? -eq 0 ] && echo "orphan LibreOffice process killed"
