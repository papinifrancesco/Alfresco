#!/bin/bash

# Backup of Alfresco

# Written by Chris Newald – localized by Clint Davis Feb 2017

 

# Configuration:

CURRENT_FOLDER=$(pwd) # Script folder

TIMESTAMP=$( date +%Y%m%d%H%M%S ) # Create timestamp

DUMP_NUM=10 # Number of backups to keep

AL_FOLDER="/opt/alfresco-community" # Alfresco folder

AL_DATA="/opt/alfresco-community/alf_data" # Alfresco data folder

TARGET_FOLDER=”/backup” # Backup destination folder

DB_HOME="/opt/alfresco-community/postgresql" # PostgreSQL folder

 

# Function - Stop Alfresco

function al_stop()

{

$AL_FOLDER/alfresco.sh stop

 

# If Alfresco does not stop we MUST exit script

# Backing up files with Alfresco working may

# corrupt data indexes!!

if [ "$?" != "0" ]; then

echo "Alfresco Stop FAILED - STOP SCRIPT!"

exit 1

else

# Alfresco Stopped successfully

echo “Alfresco Stop successful!”

fi

}

# Function - Start Alfresco

function al_start()

{

$AL_FOLDER/alfresco.sh start

}

 

# Function - Start Postgress SQL Server

function p_start()

{

$DB_HOME/scripts/ctl.sh start

}

 

# Verify that argument was provided

if [ -d "$1" ]; then

# A folder has been provided, save it

TARGET_FOLDER="$1"

else

# No argument was provided for backup location

echo "Usage: $0 [TARGET_PATH]"

exit 0

fi

 

#----------------------------------------

# 1 - Begin by stopping Alfresco

#----------------------------------------

al_stop

 

#----------------------------------------

# 2 - Backup the Alfresco database

#----------------------------------------

# Start the postgress database (which is stopped automatically

# by the Alfresco stop script

p_start

 

# Create a filename for the database tar

DB_DUMP=alfresco_db_${TIMESTAMP}.tar

 

# Backup the database to the target folder

# -Ft = Export database as tar file

$DB_HOME/bin/pg_dump alfresco -U alfresco -h localhost -F t > $TARGET_FOLDER/$DB_DUMP

 

# Check if an error was returned

if [ "$?" = "0" ]; then

echo "DB EXPORT WORKED!"

else

echo "DB EXPORT FAILED!"

fi

 

#------------------------------------------

# 3 - Backup the Alfresco content folder

#------------------------------------------

# Create a file name with timestamp

AL_DUMP=alfresco_data_${TIMESTAMP}.tgz

 

# Tar the Alfresco data folder to the backup

# to the backup folder specified

tar zcf $TARGET_FOLDER/$AL_DUMP $AL_DATA

echo "Alfresco Data folder tar complete"

 

#------------------------------------------

# 4 - Merge the database and data files

#------------------------------------------

 

# Create a backup filename with timestamp

BACKUP_FILE="alfresco_bak_${TIMESTAMP}.tgz"

tar zcf $TARGET_FOLDER/$BACKUP_FILE $TARGET_FOLDER/$AL_DUMP $TARGET_FOLDER/$DB_DUMP

echo "Database and Data File merge complete"

 

# If files were merged, delete the duplicates

if [ -f "$TARGET_FOLDER/$BACKUP_FILE" ]; then

echo "BACKUP SUCCESSFUL"

rm $TARGET_FOLDER/$AL_DUMP

rm $TARGET_FOLDER/$DB_DUMP

SUCCESS=1

fi

 

#------------------------------------------

# 5 - We're done, start the Alfresco service

#------------------------------------------

al_start

#------------------------------------------

# 6 - Remove backups older than DUMP_NUM days

#------------------------------------------

if [ "$SUCCESS" = 1 ]; then

find $TARGET_FOLDER/*.tgz -type f -mtime +${DUMP_NUM} -exec rm {} \;

echo "Backups older than 10 days have been removed"

fi
