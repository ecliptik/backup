#!/bin/bash
DATE=`date +%y%m%d`
LOG=/var/log/backup/backup.${DATE}.log
MOUNT=/mnt/backup
UUID="8cedcdbd-4ba1-43c1-9fa4-bceb3298a10e"
DISK="/dev/disk/by-uuid/${UUID}"
BACKUPCUR=backup.current
BACKUPOLD=backup.${DATE}
BACKUPDIRS="/home/ /etc/"

echo "Doing a fsck -ay on ${DISK}" >> ${LOG}
fsck -ay ${DISK} >> ${LOG} 2>&1

#Begin the backup if the mount was successfull
if mount ${DISK} ${MOUNT} >> ${LOG} 2>&1; then
echo "Mounted device ${UUID} on ${MOUNT}" >> ${LOG}

for DIR in ${BACKUPDIRS}; do
   if [ -d ${DIR}/${BACKUPCUR} ]; then
	#Move the old current backup directory to a dated dir
	mv ${MOUNT}/${DIR}/${BACKUPCUR} ${MOUNT}/${DIR}/${BACKUPOLD}
	#Create our new current dir
	mkdir ${MOUNT}/${DIR}/${BACKUPCUR}
	#Backup using rsync and hard links for incremental backups
	rsync -av --delete --link-dest=${MOUNT}/${DIR}/${BACKUPOLD} ${DIR} ${MOUNT}/${DIR}/${BACKUPCUR} >> ${LOG} 2>&1
	echo "Backup of ${UUID} to ${MOUNT}/${DIR}/${BACKUPCUR} completed" >> ${LOG}
	
   else
	#If there is no current dir assume it wasn't mounted
	echo "The directory ${MOUNT}/${DIR}/${BACKUPCUR} doesn't exist, failing" >> ${LOG}
	exit 1
   fi
done
fi
