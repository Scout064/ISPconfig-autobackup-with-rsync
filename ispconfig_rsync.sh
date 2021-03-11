#!/bin/bash

#Check if rsync is installed -> if installed go ahead to "else"
#Check if user has root privileges
#User is not root -> ask for sudo Password -> Print Message -> run apt -y install rsync as sudo and Print Message
#"else": User is root -> Print Message
#Check if rsync is installed -> if installed go ahead with next "else"
#If rsync is not installed: Print Message -> run apt -y install rsync as sudo and Print Message
#Final Step: Go ahead with script
#NB: $sudoPW -> can be Hardcoded as variable but is not advised!! 
#NB: Rather create a crontab as root and insert script so it runs as root (no PW input needed)
if ! dpkg --get-selections | grep rsync &> rsync; then
                echo "COMMAND could not be found! Installing rsync!"
elif [ "$EUID" -ne 0 ]; then
         echo "You are not root, using sudo" && read -s -p "Enter Password for sudo: " sudoPW && echo $sudoPW | sudo -s apt -y install rsync && echo "Install done, moving along!"
else
        echo "You are root, checking if rsync is installed!"
if ! dpkg --get-selections | grep rsync &> rsync; then
        echo "COMMAND could not be found! Installing rsync!" && apt -y install rsync && echo "Install done, moving along!"
else
        echo "rsync already installed, moving along!"
fi
fi
#Check and Enter Backup dir -> If not existant create as current user
if [ ! -d "/var/rsync_backup" ]; then
        echo "Directory not found, creating!" && mkdir /var/rsync_backup
else
        echo "Directory found, entering!" && cd /var/rsync_backup
fi
#Clear Backups older then 7 Days
find -type f -mtime +7 -exec rm -f {} \;
#Create tar archive (with Date) of:
#ISPconfig Standard Data and Config Folders
#/etc /var/vmail
#/var/www
#/usr/local/ispconfig
tar -czvf "backup-$(date '+%Y-%m-%d').tar.gz" /etc /var/vmail /var/www /usr/local/ispconfig
#Create mysql Database dump -> needs ~/.my.cnf to be present and configured for mysqldump
mysqldump -u root -A > /var/rsync_backup/ispconfig3-$(date '+%Y-%m-%d').sql
#rsync the Files to the Destination
rsync -ruh /var/rsync_backup rsync://USERNAME@HOST:PORT/DIRECTORY
