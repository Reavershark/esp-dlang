#!/usr/bin/env bash
set -e
docker build . --push -t jmeeuws/esp-dlang:v2.1.0_ldc-xtensa-v1.39_esp-idf-v4.8.8
docker build . --push -t jmeeuws/esp-dlang:v2.1.0
docker build . --push -t jmeeuws/esp-dlang:v2.1
docker build . --push -t jmeeuws/esp-dlang:v2
docker build . --push -t jmeeuws/esp-dlang:latest
