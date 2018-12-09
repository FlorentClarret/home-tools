#!/usr/bin/env bash

source ../utils/logger.bash;

init_repo() {
    info "Initializing ${destination_folder} as a borg repo";
    borg init --encryption=none ${destination_folder} > /dev/null 2>&1

    init_result=$?

    if [[ ${init_result} == 2 ]]; then
        info "${destination_folder} is already a borg repo";
    fi
}

backup() {

    info "${backup_name} - Start backup"

    borg create \
        --verbose \
        --stats \
        --compression lzma,9 \
        --exclude-caches \
        --exclude .sync \
        ${destination_folder}::"${backup_name}-{now}" \
        ${source_folder};

    info "${backup_name} - End backup"
}

prune() {

    info "${backup_name} - Start pruning"

    borg prune \
        --verbose \
        --stats \
        --list \
        --prefix "${backup_name}-" \
        --keep-hourly 12 \
        --keep-daily 60 \
        --keep-monthly 12 \
        --keep-yearly 3 \
        ${destination_folder};

    info "${backup_name} - End pruning"
}

CONFIGURATION_FILE="./configuration-file.example"

grep -v '^$\|^\s*\#' ${CONFIGURATION_FILE} | while read current_line; do
    backup_name=$(echo ${current_line} | cut -f1 -d',');
    source_folder=$(echo ${current_line} | cut -f2 -d',');
    destination_folder=$(echo ${current_line} | cut -f3 -d',');

    info "${backup_name} - Start"

    if [[ ! -d "${source_folder}" ]]; then
        error "Source folder ${source_folder} is unknown";
        exit 1;
    fi

    if [[ ! -d "${source_folder}" ]]; then
        info "Creating destination folder ${destination_folder}";
        mkdir -p ${destination_folder};
    fi

    init_repo;
    backup;
    prune;

    info "${backup_name} - End"

done