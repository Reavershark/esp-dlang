cmake_minimum_required(VERSION 3.16)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(malloc)

if (${IDF_VERSION_MAJOR} GREATER_EQUAL 5)
    target_link_libraries("${PROJECT_NAME}.elf" PRIVATE "${PROJECT_DIR}/dcode.a")
else()
    target_link_libraries("${PROJECT_NAME}.elf" "${PROJECT_DIR}/dcode.a")
endif()
