idf_component_register(SRCS "dummy.c")

add_prebuilt_library(dcode "libmain.a" PRIV_REQUIRES esp_driver_i2s esp_driver_gpio)
target_link_libraries(${COMPONENT_LIB} PRIVATE dcode)
