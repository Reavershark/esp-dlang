cmake_minimum_required(VERSION 3.16)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(release)
target_link_libraries("${PROJECT_NAME}.elf" PRIVATE "${PROJECT_DIR}/dcode.a")
