#define __builtin_choose_expr(c, e1, e2) e2
#define __builtin_strrchr(a, b) ""

#include "soc/io_mux_reg.h"

void setPinFunction(uint32_t pin, uint32_t func)
{
    REG_SET_FIELD(pin, MCU_SEL, func);
}
