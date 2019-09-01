#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/../utils/logger.bash";

CONFIGURATION_FILE="${HOME}/.config/youtube-dl-france-tv.conf"
RATE="300K"
MAX_VIDEOS="10"
HISTORIC="60"

usage() {
  echo "./youtube-dl-france-tv.bash: "
  echo -e "\tDownload latest videos from france tv"
  echo
  echo "Parameters: "
  echo -e "\t-c|--configuration : specify the configuration file (default $CONFIGURATION_FILE)"
  echo -e "\t-r|--rate : the maximum downloading rate (default $RATE)"
  echo -e "\t-m|--max : maximum number of video to download (default $MAX_VIDEOS)"
  echo -e "\t-H|--historic : number of days to keep each video (default $HISTORIC)"
  echo -e "\t-h|--help : Show this usage"
  echo
  echo "Configuration file format : "
  echo -e "\tshowName,url,destinationFolder"
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
    show_name=$(echo ${current_line} | cut -f1 -d',');
    show_url=$(echo ${current_line} | cut -f2 -d',');
    destination_folder=$(echo ${current_line} | cut -f3 -d',');

    info "${show_name} - Start"

    if [[ ! -d "${destination_folder}/${show_name}" ]]; then
        info "Creating destination folder ${destination_folder}/${show_name}";
        mkdir -p "${destination_folder}/${show_name}";
    fi

    for url in $(wget -q -O - "https://www.france.tv/${show_url}" | grep -o "href=\"/${show_url}[^\"]*" | grep -v 'replay-videos' | sed 's/href="/https:\/\/www.france.tv/g'); do
        info "Downloading ${url}"
        youtube-dl --download-archive "${destination_folder}/${show_name}/.archive" \
        --no-progress \
        -r ${RATE} \
        -o "${destination_folder}/${show_name}/${show_name} - %(upload_date)s - %(id)s.%(ext)s" \
        --playlist-end ${MAX_VIDEOS} \
        -f 'bestvideo[height<=480]+bestaudio/best[height<=480]' \
        "${url}"
    done

    info "${show_name} - Remove old files"

    find "${destination_folder}/${show_name}/*" -mtime "+$HISTORIC" -exec rm {} \;

    info "${show_name} - End"
done
