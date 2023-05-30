#!/usr/bin/env bash
set -e

RED="\e[31m"
ENDCOLOR="\e[0m"

if ! command -v idf.py &>/dev/null; then
    echo -e "${RED}===============================${ENDCOLOR}"
    echo -e "${RED}Loading esp-idf...${ENDCOLOR}"
    source /opt/esp-idf/export.sh >/dev/null
fi

echo -e "${RED}===============================${ENDCOLOR}"
echo -e "${RED}Building d components... ${ENDCOLOR}"

for dir in "main"; do
    if [[ -e /opt/ldc-xtensa/bin/ldc2 ]]; then
        echo -e "${RED}Using local ldc-xtensa install${ENDCOLOR}"
        dub build --root="${dir}" --compiler=/opt/ldc-xtensa/bin/ldc2 --build=release
    elif docker -v &>/dev/null; then
        echo -e "${RED}Using esp-dlang docker image${ENDCOLOR}"
        docker run --rm --tty --volume="${PWD}/${dir}:/work/${dir}" jmeeuws/esp-dlang dub build --root="${dir}" --build=release
    else
        echo -e "${RED}No local ldc-xtensa or working docker installation was found!${ENDCOLOR}"
        echo -e "${RED}Aborting...${ENDCOLOR}"
        exit 1
    fi
done

echo -e "${RED}===============================${ENDCOLOR}"
echo -e "${RED}Building other idf components... ${ENDCOLOR}"
idf.py build

echo -e "${RED}===============================${ENDCOLOR}"
