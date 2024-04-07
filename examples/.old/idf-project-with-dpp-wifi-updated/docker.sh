#!/usr/bin/env bash
set -e

docker run --rm -it --volume="${PWD}:/work" jmeeuws/esp-dlang
