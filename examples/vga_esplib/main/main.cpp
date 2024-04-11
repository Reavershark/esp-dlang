#include "driver/gpio.h"
#include "driver/periph_ctrl.h"
#include "esp_heap_caps.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "rom/gpio.h"
#include "rom/lldesc.h"
#include "soc/gpio_periph.h"
#include "soc/gpio_sig_map.h"
#include "soc/i2s_reg.h"
#include "soc/i2s_struct.h"
#include "soc/io_mux_reg.h"
#include "soc/soc.h"
#include <driver/rtc_io.h>
#include <soc/rtc.h>
#include <stdio.h>

#include <VGA/VGA.h>

VGA vga;
int pinMap[8] = {
    14,
    27,
    16,
    -1,
    -1,
    -1,
    25,
    26
};

extern "C"
void app_main(void)
{
	vga.init(vga.MODE320x240, (int*)pinMap, 8);

    while (1)
    {
        vTaskSuspend(NULL);
    }
}
