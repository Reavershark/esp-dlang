idf_component_register(
    SRCS "/dev/null"
    REQUIRES driver
)

# Code below is the same for every d component
add_custom_target(
    "${COMPONENT_NAME}_dcode" ALL
    "${PROJECT_DIR}/dbuild.sh"
    WORKING_DIRECTORY "${COMPONENT_DIR}"
    BYPRODUCTS "${COMPONENT_DIR}/lib${COMPONENT_NAME}.a"
    USES_TERMINAL
    DEPENDS "${COMPONENT_LIB}"
)
target_link_libraries(${COMPONENT_LIB} PRIVATE "${COMPONENT_DIR}/lib${COMPONENT_NAME}.a")
