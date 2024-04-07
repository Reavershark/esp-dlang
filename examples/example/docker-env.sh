#!/usr/bin/env bash
docker run \
    --rm \
    --interactive --tty \
    --volume="${PWD}":/work \
    jmeeuws/esp-dlang \
    bash -c " \
        echo Sourcing /opt/esp-idf/export.sh && \
        source /opt/esp-idf/export.sh >/dev/null && \
        ulimit -n 4096 && \
        \$SHELL \
    "
sudo chown -R $UID .
