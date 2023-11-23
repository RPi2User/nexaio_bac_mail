#!/bin/bash
#
# Skript für die automatische Datensicherung und bereitstellung vitaler Informationen für den RasPi
#
#
# 1. Aufgabe Backups der nextcloud
# 2. Aufgabe Systeminformationen sammeln
# 3. Aufgabe Summary an mich
#
######################################################
backupFile=""
recipient="your@email-adress.com"
hostname=$(hostname)

function Main(){
	ClearTemp
    BackupNCAIO
	CheckUpdates
	Send
}

function ClearTemp(){
	echo "$(hostname) Systemzusammenfassung:" > /tmp/mail.tmp
	echo "Beginn: $(date +%Y.%m.%d_%H:%M:%S)" >> /tmp/mail.tmp
	echo "Uptime: $(uptime)" >> /tmp/mail.tmp
	echo "" >> /tmp/mail.tmp
	Seperator
	echo "" >> /tmp/mail.tmp
}

function Seperator(){ #OK!
    echo "==============================================" >> /tmp/mail.tmp
}
function ThinSeparator(){ #OK!
    echo "----------------------------------------------" >> /tmp/mail.tmp
}

function BackupNC(){
	local exit_code=$?
	backupFile="NC_$(date +%Y%m%d_%H%M%S).tar"
	echo "Nextcloud wird gesichert..." >> /tmp/mail.tmp
	echo "" >> /tmp/mail.tmp
	echo "   Datei: $backupFile" >> /tmp/mail.tmp
	echo "   Dateisystem bereitstellen..." >> /tmp/mail.tmp
	mount -t ext4 /dev/disk/by-partuuid/18cbee9c-03 /mnt/backup >> /tmp/mail.tmp
	echo "   Entferne alte Backups" >> /tmp/mail.tmp
	rm $(ls -rt /mnt/backup/*.tar | head -n 1 ) &>> /tmp/mail.tmp
	echo "   Speicherplatz:" >> /tmp/mail.tmp
	df -h | grep --color=never /mnt/backup >> /tmp/mail.tmp
	echo "   Nextcloud stoppen..." >> /tmp/mail.tmp
 #	nextcloud.occ maintenance:mode --on >> /tmp/mail.tmp
	ThinSeparator
	tar cf /mnt/backup/$backupFile /var/snap/nextcloud/common/nextcloud/data 2>/dev/null
	if [ "$exit_code" = "" ]
	then
		echo "Fehlschlag Exitcode $exit_code" >> /tmp/mail.tmp
	fi
	echo "Ende: $(date +%Y.%m.%d_%H:%M:%S)" >> /tmp/mail.tmp
	umount /mnt/backup
	echo "Gebe Nextcloud wieder frei" >> /tmp/mail.tmp
 #	nextcloud.occ maintenance:mode --off >> /tmp/mail.tmp
	Seperator
}

function BackupNCAIO(){
    # NC-AIO uses BorgBackup as a AIO Backup-Solution
    # https://github.com/nextcloud/all-in-one#how-to-stopstartupdate-containers-or-trigger-the-daily-backup-from-a-script-externally
    # Describes Scripting of the Backup-Solution
    echo "Starting NC-AIO Backup:" >> /tmp/mail.tmp
    docker exec -i --env DAILY_BACKUP=1 --env START_CONTAINERS=1 nextcloud-aio-mastercontainer /daily-backup.sh >> /tmp/mail.tmp
    echo "" >> /tmp/mail.tmp
    echo "End: $(uptime)" >> /tmp/mail.tmp
    echo "" >> /tmp/mail.tmp
    Seperator
    echo "" >> /tmp/mail.tmp
}

function UpdateNC(){
    # Update NC-AIO
    echo "Updating NC-AIO" >> /tmp/mail.tmp
    docker exec -i --env AUTOMATIC_UPDATES=1  nextcloud-aio-mastercontainer /daily-backup.sh >> /tmp/mail.tmp
    echo "" >> /tmp/mail.tmp
    echo "End: $(w)" >> /tmp/mail.tmp
    echo "" >> /tmp/mail.tmp
    
}

function CheckUpdates(){
	echo "Systemaktualisierungen:" >> /tmp/mail.tmp
	apt update &>/dev/null
	echo "APT:" >> /tmp/mail.tmp
	apt list --upgradeable -qq | nl 2>/dev/null 1>> /tmp/mail.tmp 
	ThinSeparator >> /tmp/mail.tmp
    UpdateNC
	Seperator >> /tmp/mail.tmp
}
function Send(){
	cat /tmp/mail.tmp | mail -s "Systemübersicht Raspberry Pi vom $(date +%d.%m.%Y)" $recipient
	rm /tmp/mail.tmp
}
Main
