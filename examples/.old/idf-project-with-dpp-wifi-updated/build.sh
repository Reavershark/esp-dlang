#!/usr/bin/env bash
set -e

# Config
LOCAL_D_COMPONENTS="main"
BUILD_TYPE="debug"

IDF_DIR_PATH="/opt/esp-idf"
LLVM_DIR_PATH="/opt/llvm-xtensa"
LDC_DIR_PATH="/opt/ldc-xtensa"

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
for dir in $IDF_DIR_PATH $LLVM_DIR_PATH $LDC_DIR_PATH; do
    if [[ ! -d $dir ]]; then
        log "Missing dependency at ${dir}"
        exit 1
    fi
done
for cmd in python pip cmake dmd dub; do
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

if [[ ! -d build ]]; then
    log_separator
    log "Build folder doesn't exist, reconfiguring project..."
    idf.py reconfigure
fi

log_separator

log "Building d components..."
for dir in $LOCAL_D_COMPONENTS; do
    dub build --root="${dir}" --compiler="${LDC_DIR_PATH}/bin/ldc2" --build="${BUILD_TYPE}" --parallel
done

# docker run --rm -it -v "${PWD}:/work" jmeeuws/esp-dlang

log_separator

log Building other idf components...
idf.py build

log_separator

log "Done"
