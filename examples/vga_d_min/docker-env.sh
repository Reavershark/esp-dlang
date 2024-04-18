#!/usr/bin/env bash

[[ -e /dev/ttyUSB0 ]] && DEVICE_FLAG="--device=/dev/ttyUSB0"

docker run \
    --rm \
    --interactive --tty \
    --volume="${PWD}":/work \
    $DEVICE_FLAG \
    jmeeuws/esp-dlang \
    bash -c " \
        echo Sourcing /opt/esp-idf/export.sh && \
        source /opt/esp-idf/export.sh >/dev/null && \
        ulimit -n 4096 && \
        \$SHELL \
    "
sudo chown -R $UID .
