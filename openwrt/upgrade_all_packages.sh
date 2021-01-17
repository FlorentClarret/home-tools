#!/usr/bin/env bash

set -e

source /etc/openwrt_release

usage() {
  echo "./upgrade_all_packages.bash: "
  echo -e "\tUpgrade the installed open wrt packages"
  echo
  echo "Parameters: "
  echo -e "\t-y|--yes : (optionnal) Do no ask if we should upgrade the packages"
  echo -e "\t-h|--help : (optionnal) Show this usage"
  echo
}

log() {
    MESSAGE="$1"
    NOW=$(date +%Y-%m-%d/%H:%M:%S)
    echo "${NOW} - ${MESSAGE}"
}

log_package_update() {
    name="$1"
    current_version="$2"
    new_version="$3"
    now=$(date +%Y-%m-%d/%H:%M:%S)
    printf "${NOW} - %-25s | %-30s | %-30s\n" $name $current_version $new_version
}

check_openwrt_version() {
  log "Checking if a new openwrt version is available..."

  rm -f /tmp/releases.html
  wget -q https://downloads.openwrt.org/releases/ -O /tmp/releases.html
  LATEST_RELEASE=`grep -o 'href="[0-9.]*/"' /tmp/releases.html | tail -1 | cut -d'"' -f2 | cut -d'/' -f1`
  rm -f /tmp/releases.html

  if [ $LATEST_RELEASE != $DISTRIB_RELEASE ]; then
    log "/!\ New version available: $LATEST_RELEASE /!\\"
  else
    log "Your version is already up to date"
  fi
}

update_package_list() {
  log "Updating package list..."

  opkg update > /dev/null

  log "Package list updated"
}

upgrade_all_packages() {
  force_update="$1"
  if [ `opkg list-upgradable | cut -d " " -f1 | wc -l` -gt 0 ]; then
    log "Available updates:"

    printf "${NOW} - %-25s | %-30s | %-30s\n" "Name" "Current version" "New version"

    opkg list-upgradable | \
    while read line; do
      package=$(echo $line | cut -d" " -f1)
      current_version=$(echo $line | cut -d" " -f3)
      new_version=$(echo $line | cut -d" " -f5)
      log_package_update $package $current_version $new_version
    done

    valid=0
    while [ $valid == 0 ]; do
      if [ $force_update == "YES" ]; then
        choice="y"
      else
        now=$(date +%Y-%m-%d/%H:%M:%S)
        read -n1 -s -p "$now - Upgrade all available packages? [Y/n] " choice
        echo
      fi

      case $choice in
        y|Y|"" )
          valid=1
          log "Upgrading all packages..."
          opkg list-upgradable | cut -d " " -f1 | xargs -r opkg upgrade
          ;;
        n|N)
          valid=1
          log "Upgrade cancelled"
          ;;
        *)
          log "Unknown input"
          ;;
      esac
    done
  else
    log "No updates available"
  fi
}

update_installed_packages() {
  opkg list-installed > /etc/config/installed-packages.txt
}

# ====== Main ======

FORCE_UPDATE="NO"

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case ${1} in
        -y|--yes)
            FORCE_UPDATE="YES"; shift;;
        -h|--help)
            usage; exit 0;;
        *)
            usage; exit 1;;
    esac
done
set -- "${POSITIONAL[@]}"

log "Current version: $DISTRIB_ID $DISTRIB_RELEASE"

check_openwrt_version

update_package_list

upgrade_all_packages $FORCE_UPDATE

update_installed_packages

sync
