#!/bin/bash
DATE=`date +%y%m%d`
LOG=/var/log/backup/backup.${DATE}.log
MOUNT=/mnt/backup
UUID="8cedcdbd-4ba1-43c1-9fa4-bceb3298a10e"
DISK="/dev/disk/by-uuid/${UUID}"
BACKUPCUR=backup.current
BACKUPOLD=backup.${DATE}

echo "Doing a fsck -ay on ${DISK}" >> ${LOG}
fsck -ay ${DISK} >> ${LOG} 2>&1

#Begin the backup if the mount was successfull
if mount ${DISK} ${MOUNT} >> ${LOG} 2>&1; then
echo "Mounted device ${UUID} on ${MOUNT}" >> ${LOG}

   if [ -d ${BACKUPCUR} ]; then
	#Move the old current backup directory to a dated dir
	mv ${MOUNT}/${BACKUPCUR} ${MOUNT}/${BACKUPOLD}
	#Create our new current dir
	mkdir ${MOUNT}/${BACKUPCUR}
	#Backup using rsync and hard links for incremental backups
	rsync -av --delete --link-dest=${MOUNT}/${BACKUPOLD} /home/ ${MOUNT}/${BACKUPCUR} >> ${LOG} 2>&1
	echo "Backup of ${UUID} to ${BACKUPCUR} completed" >> ${LOG}
	
   else
	#If there is no current dir assume it wasn't mounted
	echo "The directory ${MOUNT}/${BACKUPCUR} doesn't exist, failing" >> ${LOG}
	exit 1
   fi
fi
