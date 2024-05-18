#!/bin/bash

# General idea:
# Mount two external drives, whose uuid are given in /etc/backups. Then check if the correct drives are connected and mount them. 
# Then perform three backups on each drive: Home (borg), System (borg), ~/Pictures/ (rsync).
# Also perform a cloud backup of Images (TODO!) 


####################
# Define Variables #
####################

# Mountpoint: location of mount
MOUNTPOINT1=/run/mount/Elements1
MOUNTPOINT2=/run/mount/Elements2

# Target: Location of Borg repos
TARGET1=$MOUNTPOINT1/BackUps/EndeavourOS/EOS-system
TARGET2=$MOUNTPOINT2/BackUps/EndeavourOS/EOS-system
TARGET3=$MOUNTPOINT1/BackUps/EndeavourOS/EOS-home 	# home disk 1
TARGET4=$MOUNTPOINT2/BackUps/EndeavourOS/EOS-home 	# home disk 2

# Archive name schema
DATE=$(date --iso-8601)

# This is the file that will later contain UUIDs of registered backup drives
DISK1=/etc/backups/backups.disk1
DISK2=/etc/backups/backups.disk2

# pw
password=$(cat /etc/backups/backup.pw)

echo "Do you want to unmount the disks after the backup? (y/n)"
read varname


########################
# Check external DISKS #
########################

for uuid1 in $(lsblk --noheadings --list --output uuid)
do
        if grep --quiet --fixed-strings $uuid1 $DISK1; then
                break
	fi
        uuid1=
done

for uuid2 in $(lsblk --noheadings --list --output uuid)
do
        if grep --quiet --fixed-strings $uuid2 $DISK2; then
                break
        fi
        uuid2=
done


if [ ! $uuid1 ]; then
        echo 'Backup disk 1 not found, exiting'
        exit 0
fi
if [ ! $uuid2 ]; then
	echo 'Backup disk 2 not found, exiting'
	exit 0
fi
echo "Both disks $uuid1 and $uuid2 are backup disks"


###############
# Mount Disks #
###############

partition_path1=/dev/disk/by-uuid/$uuid1
partition_path2=/dev/disk/by-uuid/$uuid2

# findmnt $MOUNTPOINT1 >/dev/null

if mount $partition_path1 $MOUNTPOINT1 ; then
	echo "Drive 1 mounted successfully."
else 
	echo "Error: Drive 1 could not be mounted!"
	exit 0
fi

if mount $partition_path2 $MOUNTPOINT2 ; then
	echo "Drive 2 mounted successfully."
else 
	echo "Error: Drive 2 could not be mounted!"
	exit 0
fi


###############################
# Borg Backups: System & Home #
###############################

BORG_OPTS="--stats --one-file-system --compression lz4 --checkpoint-interval 86400"

export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=no
export BORG_PASSPHRASE=$password

echo "Starting backups for $DATE"
# Backup 1: System backup on Drive 1
if borg create $BORG_OPTS \
  --exclude root/.cache \
  --exclude /home \
  $TARGET1::$DATE \
  / /boot ; then
	echo ">Completed backup 1/4 (EOS-system Disk 1)"
else
	echo "Error: Backup 1 (EOS-system Disk 1) failed."
fi

# Backup 2: System backup on Drive 2
if borg create $BORG_OPTS \
  --exclude root/.cache \
  --exclude /home \
  $TARGET2::$DATE \
  / /boot ; then
	echo ">Completed backup 2/4 (EOS-system Disk 2)"
else
	echo "Error: Backup 2 (EOS-system Disk 2) failed."
fi

# Backup 3: Home backup on Drive 1
if borg create $BORG_OPTS \
  --exclude 'sh:home/*/.cache' \
  $TARGET3::$DATE \
  /home/ ; then
	echo ">Completed backup 3/4 (EOS-home Disk 1)"
else
	echo "Error: Backup 3 (EOS-home Disk 1) failed."
fi

# Backup 4: Home backup on Drive 2
if borg create $BORG_OPTS \
  --exclude 'sh:home/*/.cache' \
  $TARGET4::$DATE \
  /home/ ; then
	echo ">Completed backup 4/4 (EOS-home Disk 2)"
else
	echo "Error: Backup 4 (EOS-home Disk 2) failed."
fi
echo "Completed backup for $DATE"




#############################
# Rsync Backups: ~/Pictures #
#############################

# TODO


############################################
# Rclone Backups: Pictures to Proton Drive #
############################################

# TODO


##################################
# Unmount the disk on user input #
##################################
if [ $varname = y ] ;
then umount $MOUNTPOINT1 && umount $MOUNTPOINT2 &&
echo "Disks at $MOUNTPOINT1 and $MOUNTPOINT2 successfully unmounted."
elif [ $varname = n ] ;
then echo "Disks are still mounted."
else 
	echo "Invalid value. Disks will not be mounted."
fi
