#!/bin/bash
DATE=`date +%Y%m%d`
LOG=/var/log/backup/backup.${DATE}.log
MOUNT=/mnt/backup
UUID="8cedcdbd-4ba1-43c1-9fa4-bceb3298a10e"
DISK="/dev/disk/by-uuid/${UUID}"
BACKUPCUR=backup.current
BACKUPOLD=backup.${DATE}
BACKUPDIRS="/home/ /etc/ /var/lib/libvirt/"
PLAYONVM=playon7
RESTORE=/etc/scripts/restore

echo "Doing a fsck -y on ${DISK}" >> ${LOG}
fsck -a ${DISK} >> ${LOG} 2>&1

#Begin the backup if the mount was successfull
if mount ${DISK} ${MOUNT} >> ${LOG} 2>&1; then
echo "Mounted device ${UUID} on ${MOUNT}" >> ${LOG}

DOMAINID=$(virsh list | grep ${PLAYONVM} | awk {'print $1'})
echo "Shutting down VM ${PLAYONVM} with domain ID ${DOMAINID}" >> ${LOG}
virsh shutdown ${DOMAINID} >> ${LOG} 2>&1
#Wait 30 seconds for domain to shutdown
sleep 30

for DIR in ${BACKUPDIRS}; do
   if [ -d ${MOUNT}/${DIR}/${BACKUPCUR} ]; then
	#Move the old current backup directory to a dated dir
        echo "Moving ${MOUNT}/${DIR}/${BACKUPCUR} to ${MOUNT}/${DIR}/${BACKUPOLD}" >> ${LOG}
	mv ${MOUNT}/${DIR}/${BACKUPCUR} ${MOUNT}/${DIR}/${BACKUPOLD}
	#Create our new current dir
	echo "Creating new  ${MOUNT}/${DIR}/${BACKUPCUR}" >> ${LOG}
	mkdir ${MOUNT}/${DIR}/${BACKUPCUR}
	#Backup using rsync and hard links for incremental backups
	echo "Creating incremental backup of ${DIR} to ${MOUNT}/${DIR}/${BACKUPCUR}" >> ${LOG}
	rsync -av --delete --link-dest=${MOUNT}/${DIR}/${BACKUPOLD} ${DIR} ${MOUNT}/${DIR}/${BACKUPCUR} >> ${LOG} 2>&1
	echo "Backup of ${DIR} to ${MOUNT}/${DIR}/${BACKUPCUR} completed" >> ${LOG}

   else
	#If there is no current dir assume it wasn't mounted
	echo "The directory ${MOUNT}/${DIR}/${BACKUPCUR} doesn't exist, failing" >> ${LOG}
	exit 1
   fi
done

echo "Starting up VM ${PLAYONVM}" >> ${LOG}
virsh start ${PLAYONVM} >> ${LOG} 2>&1

if [ ! -f ${RESTORE} ]; then
	echo "No ${RESTORE} file found, umounting ${DISK}" >> ${LOG}
	umount ${DISK} >> ${LOG} 2>&1
fi

fi
