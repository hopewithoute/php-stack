#!/bin/bash
echo "Configuring Backup"
cp -rf ./config/backup /var

chmod +x /var/backup/backup.sh

(crontab -l 2>/dev/null; echo "0 1 * * * /usr/bin/bash /var/backup/backup.sh") | crontab -