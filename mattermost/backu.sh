#!/bin/bash
#
# Script to backup a container-backed Mattermost instance.
#
# It is generally expected the script will be invoked by a cron job.
#
# The script will stop the Mattermost app service and then attempt to:
#   - rsync files to a backup location
#   - dump the db into SQL in a backup location
#
# The expectation is that backup locations will be routinely backed up
# by an external backup system that saves both full and differential backups
# of the locations.
#


#==
#
#  Set Variables
#
#==


DATESTAMP=$(date +%Y-%m-%d)

MAIL_FROM="glip_mailer@${YOUR_DOMAIN}"
ALERTS_TEAM="21484109830@888381441.mvp.${YOUR_MAIL_DOMAIN}"
MM_USER_TEAM="119096320006@888381441.mvp.${YOUR_MAIL_DOMAIN}"

MM_STOP="podman-compose stop mattermost"
MM_START="podman-compose start mattermost"

BASE_DIR="/opt/mattermost"
COMPOSE_DIR="$BASE_DIR/docker/"
BACKUP_SRC="$COMPOSE_DIR/volumes/app/"
BACKUP_DST="$BASE_DIR/mm_backup/"

LOG="$BASE_DIR/mm_backup.log"
LOG_OLD="$LOG.old"


#==
#
#  Define Functions
#
#==


## Send notifcations to appropriate contacts
NOTIFY()
{
   #mail_to = $1
   #subject = $2
   #message = $3


   echo
   echo "    notifying:      $1"
   echo "        from:       $MAIL_FROM"
   echo "        subject:    $2"
   echo "        body:       $3"
   echo

   # sending email notification via sendmail
   /usr/sbin/sendmail -t <<EOF
to: $1
from: $MAIL_FROM
subject: $2
$2:
$3
.
EOF
}

## Run commands with basic error checking
RUNCMD()
{
   echo "Running Command:  $1" >> $LOG
   eval $1

   if  [ $? != 0 ]; then
      echo "error occured when trying to run:   $1" 1>&2
      echo "error occured when trying to run:   $1" >> $LOG
      NOTIFY "$ALERTS_TEAM" "MM Backup Error" "Error occured when trying to run:   $1"

      # if a critical error occurs try to start the app back up and exit the script
      if  [[ $# -eq 2 && $2 == "CRIT" ]]; then
         echo "!!!! This is a critical error  !!!!" 1>&2
         echo "     Trying to start Mattermost app service before exiting script." 1>&2
         echo "$DATESTAMP" >> $LOG
         echo "!!!! This is a critical error  !!!!" >> $LOG
         echo "     Trying to start Mattermost app service before exiting script." >> $LOG
         mm_start
         exit 50
      fi
   fi

}

## Stop the Mattermost app service
##   Mattermost must be stopped for backups
##   We also need to be in the right working directory
##     for docker-compose commands to work as expected
mm_stop() {
   NOTIFY "$MM_USER_TEAM" "MM Backup starting" "System will be temporarily down during backup process"
   RUNCMD "cd $COMPOSE_DIR"
   RUNCMD "$MM_STOP" "CRIT"
}

## Start the Mattermost app service
##   We also need to be in the right working directory
##   for docker-compose commands to work as expected
mm_start() {
   RUNCMD "cd $COMPOSE_DIR"
   RUNCMD "$MM_START"
   NOTIFY "$MM_USER_TEAM" "MM Backup Complete" "Backup process is complete. Mattermost is starting back up and should be accessible shortly"
}

## Backup Mattermost files
##   Use rsync to save file data to a backup location
mm_backup() {
   if [[ -d $BACKUP_SRC || -d $BACKUP_DST ]]; then
      RUNCMD "podman unshare rsync -av $BACKUP_SRC/ $BACKUP_DST >> mm_backup.log"
   else
      NOTIFY "$ALERTS_TEAM" "MM Backup Error" "Rsync conditions not met"
   fi
}

## Backup Mattermost db
#    Dump SQL data to a backup location
db_backup() {
   RUNCMD "podman exec -it docker_postgres_1 pg_dump -h localhost -U mmuser mattermost > $BASE_DIR/dbBackup/mm_backup$(date +-%u).dmp"
}


#==
#
#  Run Commands
#
#==

touch $LOG
mv $LOG $LOG_OLD
touch $LOG
echo "$DATESTAMP" >> $LOG
echo "Beginning Mattermost Backup" >> $LOG

### Stop the Mattermost app service
mm_stop

### Backup Mattermost files & db
mm_backup
db_backup

## Bring Mattermost back up
mm_start

echo "$DATESTAMP" >> $LOG
echo "Backup Process Complete" >> $LOG
NOTIFY $ALERTS_TEAM "Mattermost Backup" "Mattermost backup complete"

exit 0
