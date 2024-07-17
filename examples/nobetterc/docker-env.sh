#!/usr/bin/env bash

DOCKER_RUN_ARGS=""
DOCKER_RUN_ARGS+=" --rm"
DOCKER_RUN_ARGS+=" -it"
DOCKER_RUN_ARGS+=" --volume=${PWD}:/work"
DOCKER_RUN_ARGS+=" --ulimit=nofile=8192"
[[ -e /dev/ttyUSB0 ]] && DOCKER_RUN_ARGS+=" --device=/dev/ttyUSB0"

IMAGE="jmeeuws/esp-dlang:latest"

INIT_SCRIPT=" \
echo Installing jq && apt-get update && apt-get -y install jq && \
echo Sourcing /opt/esp-idf/export.sh && source /opt/esp-idf/export.sh >/dev/null && \
bash \
"

docker run $DOCKER_RUN_ARGS $IMAGE bash -c "${INIT_SCRIPT}"

sudo chown -R $UID .
