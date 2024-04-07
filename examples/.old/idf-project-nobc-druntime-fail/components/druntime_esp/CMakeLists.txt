idf_component_register(SRCS "dummy.c")

add_prebuilt_library(druntime_esp "libdruntime_esp.a")
target_link_libraries(${COMPONENT_LIB} PRIVATE druntime_esp)
