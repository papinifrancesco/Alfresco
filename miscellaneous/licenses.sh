# Rarely, we're asked to retrived a .lic file and of course the file is not in its usual location
# We can have a look in the contentstore folder knowing that a license file can go in the range 784-888 bytes for ACS

find /$YOURPATH/alf_data/contentstore -type f -size +784c -size -888c

# in case of multiple matches make sure the file type is "application/octet-stream; charset=binary" so:

find /$YOURPATH/alf_data/contentstore -type f -size +784c -size -888c | xargs file -i

# should help
