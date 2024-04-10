#include "soc/io_mux_reg.h"

void setPinFunction(uint32_t pin, uint32_t function)
{
    REG_SET_FIELD(pin, MCU_SEL, function);
}