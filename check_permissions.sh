#!/bin/bash
# syntax: check_permissions.sh PATH USER
# example: check_permissions.sh /usr/local/scripts/myScript.sh tomcat

file=$1

# Handle non-absolute paths
if ! [[ "$file" == /* ]] ; then
    path=.
fi
dirname "$file" | tr '/' $'\n' | while read part ; do
    path="$path/$part"
    # Check for execute permissions
    if ! [[ -x "$path" ]] ; then
        echo "'$path' is blocking access."
    fi
done
if ! [[ -r "$file" ]] ; then
    echo "'$file' is not readable."
fi
echo "'$USER' can access '$file'"
namei -l $file
