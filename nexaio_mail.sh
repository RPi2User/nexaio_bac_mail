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
hostname=$(hostname)

function Main(){
	ClearTemp
    BackupNCAIO
	CheckUpdates
	Send
}

function ClearTemp(){
	echo "$(hostname) Systemzusammenfassung:" > mail.tmp
	echo "Beginn: $(date +%Y.%m.%d_%H:%M:%S)" >> mail.tmp
	echo "Uptime: $(uptime)" >> mail.tmp
	echo "" >> mail.tmp
	Seperator
	echo "" >> mail.tmp
}

function Seperator(){ #OK!
    echo "==============================================" >> mail.tmp
}
function ThinSeparator(){ #OK!
    echo "----------------------------------------------" >> mail.tmp
}

function BackupNC(){
	local exit_code=$?
	backupFile="NC_$(date +%Y%m%d_%H%M%S).tar"
	echo "Nextcloud wird gesichert..." >> mail.tmp
	echo "" >> mail.tmp
	echo "   Datei: $backupFile" >> mail.tmp
	echo "   Dateisystem bereitstellen..." >> mail.tmp
	mount -t ext4 /dev/disk/by-partuuid/18cbee9c-03 /mnt/backup >> mail.tmp
	echo "   Entferne alte Backups" >> mail.tmp
	rm $(ls -rt /mnt/backup/*.tar | head -n 1 ) &>> mail.tmp
	echo "   Speicherplatz:" >> mail.tmp
	df -h | grep --color=never /mnt/backup >> mail.tmp
	echo "   Nextcloud stoppen..." >> mail.tmp
 #	nextcloud.occ maintenance:mode --on >> mail.tmp
	ThinSeparator
	tar cf /mnt/backup/$backupFile /var/snap/nextcloud/common/nextcloud/data 2>/dev/null
	if [ "$exit_code" = "" ]
	then
		echo "Fehlschlag Exitcode $exit_code" >> mail.tmp
	fi
	echo "Ende: $(date +%Y.%m.%d_%H:%M:%S)" >> mail.tmp
	umount /mnt/backup
	echo "Gebe Nextcloud wieder frei" >> mail.tmp
 #	nextcloud.occ maintenance:mode --off >> mail.tmp
	Seperator
}

function BackupNCAIO(){
    # NC-AIO uses BorgBackup as a AIO Backup-Solution
    # https://github.com/nextcloud/all-in-one#how-to-stopstartupdate-containers-or-trigger-the-daily-backup-from-a-script-externally
    # Describes Scripting of the Backup-Solution
    echo "Starting NC-AIO Backup:" >> mail.tmp
    docker exec -i --env DAILY_BACKUP=1 --env START_CONTAINERS=1 nextcloud-aio-mastercontainer /daily-backup.sh >> mail.tmp
    echo "" >> mail.tmp
    echo "End: $(uptime)" >> mail.tmp
    echo "" >> mail.tmp
    Seperator
    echo "" >> mail.tmp
}

function UpdateNC(){
    # Update NC-AIO
    echo "Updating NC-AIO" >> mail.tmp
    docker exec -i --env AUTOMATIC_UPDATES=1  nextcloud-aio-mastercontainer /daily-backup.sh >> mail.tmp
    echo "" >> mail.tmp
    echo "End: $(uptime)" >> mail.tmp
    echo "" >> mail.tmp
    
}

function CheckUpdates(){
	echo "Systemaktualisierungen:" >> mail.tmp
	apt update &>/dev/null
	echo "APT:" >> mail.tmp
	apt list --upgradeable -qq 1> mail.tmp 2>/dev/null
	ThinSeparator >> mail.tmp
    UpdateNC
	Seperator >> mail.tmp
}
function Send(){
	cat mail.tmp | mail -s "Systemübersicht Raspberry Pi vom $(date +%d.%m.%Y)" florian@hatzfeld.biz
	rm mail.tmp
}
Main
