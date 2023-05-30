idf_component_register(SRCS "main.c")

add_prebuilt_library(dcode "../dcode/libdcode.a" PRIV_REQUIRES app_update)
target_link_libraries(${COMPONENT_LIB} PRIVATE dcode)
