idf_component_register(SRCS "dummy.c")

add_prebuilt_library(dcode "libmain.a" PRIV_REQUIRES app_update)
target_link_libraries(${COMPONENT_LIB} PRIVATE dcode)
