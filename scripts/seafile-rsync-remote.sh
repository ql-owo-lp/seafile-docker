#!/bin/bash

# install mutt to be able to send email notification
# apt-get install mutt

MAIL_RECEIVER='kevixw@gmail.com'
SOURCE_PATH='/opt/seafile/'  # Trailing / is critical!
BACKUP_PATH='/mnt/storage/seafile/' # Trailing / is critical!
REMOTE_HOST='root@cloudfront-static.duckdns.org'
REMOTE_PORT='52022'
LOCAL_USR='rock64'

RSYNC_LOCK='/var/lock/seafile-backup.lock'

if [ -f "${RSYNC_LOCK}" ]; then
    echo "The seafile backup script is already running."
    exit 2
fi
echo "$$" > "${RSYNC_LOCK}"

extraOpts=
if [ "`date '+%d'`" -eq 1 ]; then
    # if today is the first day of this month, do a checksum sync
    extraOpts="${extraOpts} --checksum"
fi

mkdir -p "${BACKUP_PATH}"

BACKUP_LOG_FILE="${BACKUP_PATH}/backup.log"
BACKUP_FSCK_LOG_FILE="${BACKUP_PATH}/seafile-fsck.log"

echo "$(date) - Backup process started." > ${BACKUP_LOG_FILE}

# ======= rsync part starts here ============
echo "$(date) - Backing up snapshot.." >> ${BACKUP_LOG_FILE}
retry_count=10
while [[ $retry_count > 0 ]]; do
    rsync -avzhpSH ${extraOpts} --delete --force -e "ssh -p ${REMOTE_PORT}" "${REMOTE_HOST}:${SOURCE_PATH}" "${BACKUP_PATH}/synced/" >> "${BACKUP_LOG_FILE}" 2>&1
    if [ "$?" = "0" ]; then
        echo "$(date) - Rsync from remote to 'synced' directory succeed."
	break
    elif grep -q "Broken pipe" "${BACKUP_LOG_FILE}"; then
        echo "$(date) - Unstable connection.. retrying." >> ${BACKUP_LOG_FILE}
	sleep 10
    else
        echo "$(date) - Rsync failed. Retrying."
	sleep 10
    fi
    let retry_count=retry_count-1
done
# ===========================================

# Here we do not delete any file
# if we want to fully sync two sides, uncomment the following line
extraOpts="${extraOpts} --delete"

echo "$(date) - Synchrinizing to 'archived'"
rsync -avhpSH ${extraOpts} --force "${BACKUP_PATH}/synced/" "${BACKUP_PATH}/archived/" >> ${BACKUP_LOG_FILE} 2>&1

mkdir -p "${BACKUP_PATH}/logs"
gzip -9 -c "${BACKUP_LOG_FILE}" > "${BACKUP_LOG_FILE}.gz"
mv ${BACKUP_LOG_FILE}.gz ${BACKUP_PATH}/logs/rsync_$(date +"%F").log.gz
# remove files older than 30 days
find ${BACKUP_PATH}/logs/rsync_* -mtime +30 -type f -delete

rm -f "${RSYNC_LOCK}"
echo "$(date) - fsck finished."
