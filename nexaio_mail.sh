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
	BackupNC
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
function CheckUpdates(){
	echo "Systemaktualisierungen:" >> mail.tmp
	apt update &>/dev/null
	echo "APT:" >> mail.tmp
	apt list --upgradeable -qq >> mail.tmp
	ThinSeparator >> mail.tmp
	echo "SNAP:" >> mail.tmp
	snap refresh 2>> mail.tmp
	Seperator >> mail.tmp
}
function Send(){
	cat mail.tmp | mail -s "Systemübersicht Raspberry Pi vom $(date +%d.%m.%Y)" florian@hatzfeld.biz
	rm mail.tmp
}
Main
