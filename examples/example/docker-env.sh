#!/usr/bin/env bash
docker run \
    --rm \
    --interactive --tty \
    --volume="${PWD}":/work \
    jmeeuws/esp-dlang \
    bash -c " \
        echo Sourcing /opt/esp-idf/export.sh && \
        source /opt/esp-idf/export.sh >/dev/null && \
        \$SHELL \
    "
sudo chown -R $UID .
