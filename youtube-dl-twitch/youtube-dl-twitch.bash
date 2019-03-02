#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/../utils/logger.bash";

usage() {
  echo "./youtube-dl-twitch.bash: "
  echo -e "\tDownload the last 10 videos of each streamer"
  echo
  echo "Parameters: "
  echo -e "\t-c|--configuration : specify the configuration file"
  echo -e "\t-r|--rate : the maximum downloading rate (default 300K)"
  echo -e "\t-m|--max : maximum number of video to download (default 10)"
  echo -e "\t-h|--help : Show this usage"
  echo
  echo "Configuration file format : "
  echo -e "\tchannelUrl,destinationFolder"
}

CONFIGURATION_FILE="${HOME}/.config/youtube-dl-twitch.conf"
RATE="300K"
MAX_VIDEOS="10"

POSITIONAL=();
while [[ $# -gt 0 ]]; do
    case ${1} in
        -c|--configuration)
            CONFIGURATION_FILE=${2}; shift; shift;;
        -r|--rate)
            RATE=${2}; shift; shift;;
        -m|--max)
            MAX_VIDEOS=${2}; shift; shift;;
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
    channel_url=$(echo ${current_line} | cut -f1 -d',');
    destination_folder=$(echo ${current_line} | cut -f2 -d',');

    info "${channel_url} - Start"

    if [[ ! -d "${destination_folder}" ]]; then
        info "Creating destination folder ${destination_folder}";
        mkdir -p ${destination_folder};
    fi

    youtube-dl --download-archive ${destination_folder}/.archive \
        --no-progress \
        -r ${RATE} \
        -o "${destination_folder}/%(uploader)s - %(upload_date)s - %(id)s.%(ext)s" \
        --playlist-end ${MAX_VIDEOS} \
        -f 'bestvideo[height<=480]+bestaudio/best[height<=480]' \
        ${channel_url}

    info "${channel_url} - End"
done