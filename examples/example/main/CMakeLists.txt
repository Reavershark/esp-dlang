idf_component_register(
    SRCS "/dev/null"
    PRIV_REQUIRES driver
)

add_custom_target(
    dcode
    ALL
    "${PROJECT_DIR}/dbuild.sh"
    WORKING_DIRECTORY "${COMPONENT_DIR}"
    USES_TERMINAL
    DEPENDS "${COMPONENT_LIB}"
    BYPRODUCTS "${COMPONENT_DIR}/libmain.a"
)
target_link_libraries(${COMPONENT_LIB} PRIVATE "${COMPONENT_DIR}/libmain.a")
