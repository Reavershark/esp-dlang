idf_component_register(
    SRCS "source/i2s_c_code.c"
    INCLUDE_DIRS "."
    PRIV_REQUIRES driver
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
