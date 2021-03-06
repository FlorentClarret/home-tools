#!/usr/bin/env bash

# https://wiki.kobol.io/helios64/ups

set -e

usage() {
  echo "./helios_watch_ups.bash: "
  echo -e "\tWatch the UPS status and stop the host if needed"
  echo
  echo "Parameters: "
  echo -e "\t-l|--level : (optionnal) The level from which you want to stop the ost"
  echo -e "\t-d|--discord : (optionnal) Discord webhook url"
  echo -e "\t-h|--help : (optionnal) Show this usage"
  echo
}

log() {
    MESSAGE="$1";
    NOW=$(date +%Y-%m-%d/%H:%M:%S,%3N);
    echo "${NOW} - ${MESSAGE}";
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

# ====== Main ======

MIN_BATTERY_LEVEL="916"
DISCORD_URL="NO"

POSITIONAL=();
while [[ $# -gt 0 ]]; do
    case ${1} in
        -d|--discord)
            DISCORD_URL=${2}; shift; shift;;
        -l|--level)
            MIN_BATTERY_LEVEL=${2}; shift; shift;;
        -h|--help)
            usage; exit 0;;
        *)
            usage; exit 1;;
    esac
done
set -- "${POSITIONAL[@]}"

ON_BATTERY=$(cat /sys/class/power_supply/gpio-charger/online)
CHARGING_STATUS=$(cat /sys/class/power_supply/gpio-charger/status)
CURRENT_LEVEL=$(scale=0;echo "`cat /sys/bus/iio/devices/iio:device0/in_voltage2_raw` * `cat /sys/bus/iio/devices/iio:device0/in_voltage_scale`/1" | bc)

if [[ ${CHARGING_STATUS} == "Charging" ]] && [[ ${ON_BATTERY} -eq "1" ]]; then
  log "Helios is charging. Current power level $CURRENT_LEVEL"
  notify_discord $DISCORD_URL "Helios is charging. Current power level $CURRENT_LEVEL"
else
  if [[ ${ON_BATTERY} -eq "0" ]]; then
      log "Helios is on battery. Current power level $CURRENT_LEVEL"
      notify_discord $DISCORD_URL "Helios is charging. Current power level $CURRENT_LEVEL"

      if [[ "${CURRENT_LEVEL}" -lt ${MIN_BATTERY_LEVEL} ]]; then
          log "Shutdown now !"
          notify_discord $DISCORD_URL "Shutdown now !"
          poweroff
      fi
  fi
fi

exit 0
