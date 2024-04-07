#!/usr/bin/env bash
set -e

function log
{
    RED="\e[31m"
    ENDCOLOR="\e[0m"
    echo -e "${RED}${@}${ENDCOLOR}"
}

function log_separator
{
    log "==============================="
}

if ! command -v idf.py &>/dev/null; then
    log_separator
    log "Loading esp-idf..."
    if [[ -d /opt/esp-idf ]]; then
        source /opt/esp-idf/export.sh >/dev/null
    else
        log "No esp-idf installation was found. One is required even with docker."
        log "Aborting..."
        exit 1
    fi
fi

if [[ ! -d build ]]; then
    log_separator
    log "Creating the build folder..."
    idf.py reconfigure
fi

log_separator

log "Building d components..."
for dir in "main"; do
    if [[ -e /opt/ldc-xtensa/bin/ldc2 ]]; then
        log "Using local ldc-xtensa install"
        dub build --root="${dir}" --compiler=/opt/ldc-xtensa/bin/ldc2 --build=debug
    elif docker -v &>/dev/null; then
        log "Using esp-dlang docker image"
        docker run \
            --rm -it \
            --volume="/opt/esp-idf/:/opt/esp-idf/:ro" \
            --volume="${HOME}/.espressif:/root/.espressif/" \
            --volume="${PWD}/:/work/" \
            jmeeuws/esp-dlang \
            dub build \
                --root="${dir}" \
                --build=debug
    else
        log "No local ldc-xtensa or working docker installation was found!"
        log "Aborting..."
        exit 1
    fi
done

log_separator

log "Building other idf components..."
idf.py build

log_separator
