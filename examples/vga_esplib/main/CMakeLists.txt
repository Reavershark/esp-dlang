idf_component_register(
    SRCS "main.cpp" "I2S/I2S.cpp" "VGA/VGA.cpp"
    INCLUDE_DIRS "."
    PRIV_REQUIRES esp_driver_i2s esp_driver_gpio driver
)
