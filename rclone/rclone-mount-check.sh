#!/bin/bash
# 1. Change paths
# 2. for mount and log file & create mountchek file.
# 3. Add to crontab -e (paste the line bellow, without # in front)
# * * * * *  /root/rclone-mount-check.sh >/dev/null 2>&1
# Make script executable with: chmod a+x /root/rclone-mount-check.sh

LOGFILE="/root/rclone-mount-check.log"
RCLONEREMOTE="gdrive:"
MPOINT="/home/stephen/gdrive"
CHECKFILE="mountcheck"

if pidof -o %PPID -x "$0"; then
    echo "$(date "+%d.%m.%Y %T") EXIT: Already running." | tee -a "$LOGFILE"
    exit 1
fi

if [[ -f "$MPOINT/$CHECKFILE" ]]; then
    echo "$(date "+%d.%m.%Y %T") INFO: Check successful, $MPOINT mounted." | tee -a "$LOGFILE"
    exit
else
    echo "$(date "+%d.%m.%Y %T") ERROR: $MPOINT not mounted, remount in progress." | tee -a "$LOGFILE"
    # Unmount before remounting
    while mount | grep "on ${MPOINT} type" > /dev/null
    do
        echo "($wi) Unmounting $mount"
        fusermount -uz $MPOINT | tee -a "$LOGFILE"
        cu=$(($cu + 1))
        if [ "$cu" -ge 5 ];then
            echo "$(date "+%d.%m.%Y %T") ERROR: Folder could not be unmounted exit" | tee -a "$LOGFILE"
            exit 1
            break
        fi
        sleep 1
    done
    rclone mount \
        --allow-non-empty \
        --allow-other \
        --copy-links \
        --no-gzip-encoding \
        --no-check-certificate \
        $RCLONEREMOTE $MPOINT &

    while ! mount | grep "on ${MPOINT} type" > /dev/null
    do
        echo "($wi) Waiting for mount $mount"
        c=$(($c + 1))
        if [ "$c" -ge 4 ] ; then break ; fi
        sleep 1
    done
    if [[ -f "$MPOINT/$CHECKFILE" ]]; then
        echo "$(date "+%d.%m.%Y %T") INFO: Remount successful." | tee -a "$LOGFILE"
    else
      echo "$(date "+%d.%m.%Y %T") CRITICAL: Remount failed." | tee -a "$LOGFILE"
    fi
fi
exit
