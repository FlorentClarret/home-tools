#!/usr/bin/env bash

# Requirements : bash, curl

# In my crontab : /root/scripts/backup.sh -d >> /var/log/backup/backup.$(date '+%Y-%m-%d').log 2>&1

set -e

usage() {
  echo "./backup.bash: "
  echo -e "\tGenerate a backup file"
  echo
  echo "Parameters: "
  echo -e "\t-p|--path : (optionnal) Folder where to store the backup files. Default to /root/backups/"
  echo -e "\t-d|--discord : (optionnal) Discord webhook url"
  echo -e "\t-h|--help : (optionnal) Show this usage"
  echo
}

notify_discord() {
  URL="$1"
  MESSAGE="$2"

  if [ "$URL" != "NO" ]; then
    curl -X POST \
      -s \
      -H "Content-Type: application/json" \
      --data '{"username": "Router", "content": "'"$MESSAGE"'"}' \
      $URL
  fi
}

log() {
    MESSAGE="$1"
    NOW=$(date +%Y-%m-%d/%H:%M:%S)
    echo "${NOW} - ${MESSAGE}"
}

# ====== Main ======

DISCORD_URL="NO"
BACKUP_PATH="/root/backups"

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case ${1} in
        -d|--discord)
            DISCORD_URL=${2}; shift; shift;;
        -d|--discord)
            BACKUP_PATH=${2}; shift; shift;;
        -h|--help)
            usage; exit 0;;
        *)
            usage; exit 1;;
    esac
done
set -- "${POSITIONAL[@]}"

notify_discord $DISCORD_URL "Generating the backup file"

mkdir -p $BACKUP_PATH

umask go=
sysupgrade -b $BACKUP_PATH/backup-${HOSTNAME}-$(date +%F).tar.gz

notify_discord $DISCORD_URL "Backup file generated"
