cmake_minimum_required(VERSION 3.16)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(hello_world)
target_link_libraries("${PROJECT_NAME}.elf" "${PROJECT_DIR}/dcode.a")
