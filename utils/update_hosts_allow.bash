#!/usr/bin/env bash

set -e

usage() {
  echo "./update_allow_hosts.bash: "
  echo -e "\tAdd a specific allowed address for ssh"
  echo
  echo "Parameters: "
  echo -e "\t-h|--hostname : The hostname to get the ip from"
  echo -e "\t-f|--filepath : The path to the hosts.allow file"
  echo -e "\t-h|--help : Show this usage"
  echo
}

get_ip_from_hostname() {
  local host=$1
  local ip=$(getent ahosts $host | grep -v ':' | grep 'STREAM'  | awk '{ print $1 }')
  if [[ $ip =~ .*:.* ]]; then
    echo "[$ip]"
  else
    echo $ip
  fi
}

# ====== Main ======

HOSTNAME=""
HOST_ALLOW_FILE_PATH="/etc/hosts.allow"

POSITIONAL=();
while [[ $# -gt 0 ]]; do
    case ${1} in
        -h|--hostname)
            HOSTNAME=${2}; shift; shift;;
        -f|--filepath)
            HOST_ALLOW_FILE_PATH=${2}; shift; shift;;
        -H|--help)
            usage; exit 0;;
        *)
            usage; exit 1;;
    esac
done
set -- "${POSITIONAL[@]}"

if [[ ! -f ${HOST_ALLOW_FILE_PATH} ]]; then
    echo "${HOST_ALLOW_FILE_PATH} no such file";
    exit 1;
fi

ip="$(get_ip_from_hostname $HOSTNAME)"

if  [[ -z "$ip" ]]; then
    echo "Can not find ip address from hostname $HOSTNAME";
    exit 1;
fi

new_line="# $HOSTNAME, updated on $(date +'%d-%m-%Y') at $(date +'%T') \nsshd: $ip "

if grep -q "$HOSTNAME" "$HOST_ALLOW_FILE_PATH"; then
  line=$(grep -n "$HOSTNAME" "$HOST_ALLOW_FILE_PATH" | cut -d':' -f1)
  sed -i "$line,$((line+1))d" $HOST_ALLOW_FILE_PATH
fi

echo -e $new_line >> "$HOST_ALLOW_FILE_PATH"

exit 0
