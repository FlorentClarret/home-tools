#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/../utils/logger.bash";

CONFIGURATION_FILE="${HOME}/.config/youtube-dl-twitch.conf"
RATE="300K"
MAX_VIDEOS="10"
HISTORIC="15"

usage() {
  echo "./youtube-dl-twitch.bash: "
  echo -e "\tDownload latest videos from twitch"
  echo
  echo "Parameters: "
  echo -e "\t-c|--configuration : specify the configuration file (default $CONFIGURATION_FILE)"
  echo -e "\t-r|--rate : the maximum downloading rate (default $RATE)"
  echo -e "\t-m|--max : maximum number of video to download (default $MAX_VIDEOS)"
  echo -e "\t-H|--historic : number of days to keep each video (default $HISTORIC)"
  echo -e "\t-h|--help : Show this usage"
  echo
  echo "Configuration file format : "
  echo -e "\tchannelName,channelUrl,destinationFolder"
}

POSITIONAL=();
while [[ $# -gt 0 ]]; do
    case ${1} in
        -c|--configuration)
            CONFIGURATION_FILE=${2}; shift; shift;;
        -r|--rate)
            RATE=${2}; shift; shift;;
        -m|--max)
            MAX_VIDEOS=${2}; shift; shift;;
        -H|--historic)
            HISTORIC=${2}; shift; shift;;
        -h|--help)
            usage; exit 0;;
        *)
            usage; exit 1;;
    esac
done
set -- "${POSITIONAL[@]}"

if [[ ! -f ${CONFIGURATION_FILE} ]]; then
    error "${CONFIGURATION_FILE} no such file";
    exit 1;
fi

grep -v '^$\|^\s*\#' ${CONFIGURATION_FILE} | while read current_line; do
    channel_name=$(echo ${current_line} | cut -f1 -d',');
    channel_url=$(echo ${current_line} | cut -f2 -d',');
    destination_folder=$(echo ${current_line} | cut -f3 -d',');

    info "${channel_name} - Start"

    if [[ ! -d "${destination_folder}/${channel_name}" ]]; then
        info "Creating destination folder ${destination_folder}/${channel_name}";
        mkdir -p "${destination_folder}/${channel_name}";
    fi

    youtube-dl --download-archive ${destination_folder}/${channel_name}/.archive \
        --no-progress \
        -r ${RATE} \
        -o "${destination_folder}/${channel_name}/%(uploader)s - %(upload_date)s - %(id)s.%(ext)s" \
        --playlist-end ${MAX_VIDEOS} \
        -f 'bestvideo[height<=480]+bestaudio/best[height<=480]' \
        ${channel_url}

    info "${channel_name} - Remove old file"

    find "${destination_folder}/${channel_name}/" -mtime "+$HISTORIC" -exec rm -f {} \;

    info "${channel_name} - End"
done
