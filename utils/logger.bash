#!/usr/bin/env bash

log() {
    LEVEL="$1";
    MESSAGE="$2";
    NOW=$(date +%Y-%m-%d/%H:%M:%S,%3N);
    echo "[${LEVEL}] - ${NOW} - ${MESSAGE}";
}

info() {
    log "INFO" "$1"
}

warn() {
    log "WARN" "$1"
}

error() {
    log "ERROR" "$1"
}