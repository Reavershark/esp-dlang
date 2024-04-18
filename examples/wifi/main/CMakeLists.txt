idf_component_register(
    SRCS
        "source/idfd/tcp.c"
        "source/idf/esp_common/esp_err/idf_esp_common_esp_err_c_code.c"
        "source/idf/esp_wifi/idf_esp_wifi_c_code.c"
    INCLUDE_DIRS "."
    PRIV_REQUIRES nvs_flash esp_wifi
)

# Code below is the same for every d component
add_custom_target(
    "${COMPONENT_NAME}_dcode" ALL
    "${PROJECT_DIR}/dbuild.sh"
    WORKING_DIRECTORY "${COMPONENT_DIR}"
    BYPRODUCTS "${COMPONENT_DIR}/lib${COMPONENT_NAME}.a"
    USES_TERMINAL
)
target_link_libraries(${COMPONENT_LIB} PRIVATE "${COMPONENT_DIR}/lib${COMPONENT_NAME}.a")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,--start-group") # Allow .a file order
