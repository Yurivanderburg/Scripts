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
TARGET1=$MOUNTPOINT1/BackUps/EndeavourOS/EOS-system # system disk 1
TARGET2=$MOUNTPOINT2/BackUps/EndeavourOS/EOS-system # system disk 2
TARGET3=$MOUNTPOINT1/BackUps/EndeavourOS/EOS-home 	# home disk 1
TARGET4=$MOUNTPOINT2/BackUps/EndeavourOS/EOS-home 	# home disk 2
TARGET5=$MOUNTPOINT1/BackUps/EndeavourOS/Pictures   # pics disk 1
TARGET6=$MOUNTPOINT2/BackUps/EndeavourOS/Pictures   # pics disk 2

# Archive name schema
DATE=$(date --iso-8601)

# This is the file that will later contain UUIDs of registered backup drives
DISK1=/etc/backups/backups.disk1
DISK2=/etc/backups/backups.disk2

# Read password from local file
password=$(cat /etc/backups/backup.pw)


echo "Do you want to compact the repositories after the backup? (y/n)"
read varname_compact

echo "Do you want to separately backup ~/Pictures? (y/n)"
read varname_pictures


########################
# Check external DISKS #
########################

# Check whether mount directory exists
if ! [ -d $MOUNTPOINT1 ]; then
    mkdir $MOUNTPOINT1
fi

if ! [ -d $MOUNTPOINT2 ]; then
	mkdir $MOUNTPOINT2 
fi

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

# Start backups sequentially on a single Disk, but run backups
# on both Disks in parallel

# Disk 1
(
	# System backup
	if borg create $BORG_OPTS \
	--exclude root/.cache \
  	--exclude /home \
  	$TARGET1::$DATE \
  	/ /boot ; then
		echo ">Completed backup 1/6 (EOS-system Disk 1)"
	else
		echo "Error: Backup 1 (EOS-system Disk 1) failed."
	fi

	# Home backup
	if borg create $BORG_OPTS \
  	--exclude 'sh:home/*/.cache' \
  	--exclude /run/mount/ \
  	$TARGET3::$DATE \
  	/home/ ; then
		echo ">Completed backup 3/6 (EOS-home Disk 1)"
	else
		echo "Error: Backup 3 (EOS-home Disk 1) failed."
	fi
) &

# Disk 2

(
	# System backup
	if borg create $BORG_OPTS \
  	--exclude root/.cache \
  	--exclude /home \
  	$TARGET2::$DATE \
  	/ /boot ; then
		echo ">Completed backup 2/6 (EOS-system Disk 2)"
	else
		echo "Error: Backup 2 (EOS-system Disk 2) failed."
	fi

	# Home backup
	if borg create $BORG_OPTS \
  	--exclude 'sh:home/*/.cache' \
  	--exclude  /run/mount/ \
  	$TARGET4::$DATE \
  	/home/ ; then
		echo ">Completed backup 4/6 (EOS-home Disk 2)"
	else
		echo "Error: Backup 4 (EOS-home Disk 2) failed."
	fi
) &

wait # Wait for all backups to be done


################
# Borg Compact #
################

if [ $varname_compact = y ] ; then
	for REPO in "$TARGET1" "$TARGET2" "$TARGET3" "$TARGET4"
	do (
		echo "Start borg compacting of $REPO."
		borg compact $REPO
	) &
done

wait


#############################
# Rsync Backups: ~/Pictures #
#############################

if [ $varname_pictures = y ] ; then 
	
	# Again start in parallel
	for TARGET in "$TARGET5" "$TARGET6"
	do (
		echo "Start backup of ~/Pictures to $TARGET"
		rsync -a --info=progress2 --no-inc-recursive /home/yuri/Pictures/ "$TARGET"
		echo "Completed backup of ~/Pictures to $TARGET" 
	) &
done

wait 

fi

####################
# Unmount the disk #
####################

umount $MOUNTPOINT1 && umount $MOUNTPOINT2
echo "Disks at $MOUNTPOINT1 and $MOUNTPOINT2 successfully unmounted."


echo "Backup complete."
