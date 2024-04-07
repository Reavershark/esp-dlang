#!/usr/bin/env bash
set -e

# Config
LOCAL_D_COMPONENTS="main"

IDF_DIR_PATH="/opt/esp-idf"

# Utils
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

# Check dependencies
for dir in $IDF_DIR_PATH; do
    if [[ ! -d $dir ]]; then
        log "Missing dependency at ${dir}"
        exit 1
    fi
done
for cmd in dmd dub; do
    if ! which $cmd >/dev/null; then
        log "Missing dependency: ${cmd}"
        exit 1
    fi
done

if ! command -v idf.py &>/dev/null; then
    log_separator
    log "Loading esp-idf..."
    source "${IDF_DIR_PATH}/export.sh" >/dev/null
fi

echo "Running idf.py fullclean"
idf.py fullclean
rm -r build &>/dev/null
log_separator

for dir in $LOCAL_D_COMPONENTS; do
    log_separator
    echo "Cleaning component ${dir}"
    cd "${dir}"

    dub clean
    rm *.a &>/dev/null
    ./dpp_clean.d

    cd ..
done
