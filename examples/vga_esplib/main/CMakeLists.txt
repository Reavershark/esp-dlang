idf_component_register(
    SRCS "ccode.c"
    #SRCS "main.cpp" "I2S/i2s->cpp" "VGA/VGA.cpp"
    INCLUDE_DIRS "."
    PRIV_REQUIRES driver
)
