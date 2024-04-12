module app.main;

import app.i2s;
import app.util;
import app.video_timings;

import idf.esp_driver_gpio.gpio : gpio_set_direction;
import idf.esp_hw_support.esp_private.periph_ctrl : periph_module_enable;
import idf.esp_hw_support.port.soc.rtc : rtc_clk_apll_coeff_set, rtc_clk_apll_enable;
import idf.esp_rom.gpio : gpio_matrix_out;
import idf.esp_rom.lldesc : lldesc_t;
import idf.freertos : vTaskSuspend;
import idf.hal.gpio_types : GPIO_MODE_DEF_OUTPUT, gpio_mode_t;
import idf.heap.caps : MALLOC_CAP_DMA;
import idf.soc.gpio_num : gpio_num_t;
import idf.soc.gpio_periph : GPIO_PIN_MUX_REG;
import idf.soc.gpio_sig_map : I2S0O_DATA_OUT0_IDX, I2S1O_DATA_OUT0_IDX;
import idf.soc.i2s_reg : I2S_OUT_DATA_BURST_EN, I2S_OUTDSCR_BURST_EN;
import idf.soc.i2s_struct : I2S0, I2S1, i2s_dev_t;
import idf.soc.io_mux_reg : MCU_SEL_S, MCU_SEL_V, PIN_FUNC_GPIO;
import idf.soc.periph_defs : PERIPH_I2S0_MODULE, PERIPH_I2S1_MODULE, periph_module_t;

int[8] pinMap = [
    14,
    27,
    16,
    -1,
    -1,
    -1,
    25,
    26
];

alias Color = ubyte;

extern(C) void d_main(
    FinishClockSetupCFuncType finishClockSetupCFunc,
    StartTransmittingCFuncType startTransmittingCFunc
)
{
    app.i2s.finishClockSetupCFunc = finishClockSetupCFunc;
    app.i2s.startTransmittingCFunc = startTransmittingCFunc;


    const VideoTimings* vt = &videoTimings320x480;


    Color*[] frameBuffer = dallocArray!(Color*)(vt.v.res / vt.vDiv);
    foreach(ref Color* ptr; frameBuffer)
        ptr = dallocArrayCaps!Color(vt.h.res, MALLOC_CAP_DMA, 0xC1).ptr;


    ubyte[] inactiveBuffer      = dallocArrayCaps!Color(vt.inactiveWidth, MALLOC_CAP_DMA);
    ubyte[] vSyncInactiveBuffer = dallocArrayCaps!Color(vt.inactiveWidth, MALLOC_CAP_DMA);
    ubyte[] blankActiveBuffer   = dallocArrayCaps!Color(vt.activeWidth, MALLOC_CAP_DMA);
    ubyte[] vSyncActiveBuffer   = dallocArrayCaps!Color(vt.activeWidth, MALLOC_CAP_DMA);

    for (int i = 0; i < vt.inactiveWidth; i++)
    {
        if (vt.h.front <= i && i < vt.h.front + vt.h.sync)
        {
            vSyncInactiveBuffer[i ^ 2] = 0;
            inactiveBuffer[i ^ 2] = 0x80;
        }
        else
        {
            vSyncInactiveBuffer[i ^ 2] = 0x40;
            inactiveBuffer[i ^ 2] = 0xC0;
        }
    }
    for (int i = 0; i < vt.activeWidth; i++)
    {
        blankActiveBuffer[i ^ 2] = 0xC0;
        vSyncActiveBuffer[i ^ 2] = 0x40;
    }


    lldesc_t[] descriptors = dallocArrayCaps!lldesc_t(vt.v.total * 2, MALLOC_CAP_DMA);
    for (int i = 0; i < descriptors.length; i++)
    {
        descriptors[i].length = 0;
        descriptors[i].size = 0;
        descriptors[i].owner = 1;
        descriptors[i].sosf = 0;
        descriptors[i].buf = null;
        descriptors[i].offset = 0;
        descriptors[i].empty = 0;
        descriptors[i].eof = 1;
        descriptors[i].qe.stqe_next = null;
    }

    for (int i = 0; i < descriptors.length; i++)
        descriptors[i].qe.stqe_next = &descriptors[(i + 1) % descriptors.length];

    int d = 0;
    for (int i = 0; i < vt.v.front; i++)
    {
        descriptors[d].length = vt.inactiveWidth;
        descriptors[d].size = vt.inactiveWidth;
        descriptors[d].buf = cast(ubyte*) inactiveBuffer.ptr;
        d++;
        descriptors[d].length = vt.activeWidth;
        descriptors[d].size = vt.activeWidth;
        descriptors[d].buf = cast(ubyte*) blankActiveBuffer.ptr;
        d++;
    }
    for (int i = 0; i < vt.v.sync; i++)
    {
        descriptors[d].length = vt.inactiveWidth;
        descriptors[d].size = vt.inactiveWidth;
        descriptors[d].buf = cast(ubyte*) vSyncInactiveBuffer.ptr;
        d++;
        descriptors[d].length = vt.activeWidth;
        descriptors[d].size = vt.activeWidth;
        descriptors[d].buf = cast(ubyte*) vSyncActiveBuffer.ptr;
        d++;
    }
    for (int i = 0; i < vt.v.back; i++)
    {
        descriptors[d].length = vt.inactiveWidth;
        descriptors[d].size = vt.inactiveWidth;
        descriptors[d].buf = cast(ubyte*) inactiveBuffer;
        d++;
        descriptors[d].length = vt.activeWidth;
        descriptors[d].size = vt.activeWidth;
        descriptors[d].buf = cast(ubyte*) blankActiveBuffer;
        d++;
    }
    for (int i = 0; i < vt.v.res; i++)
    {
        descriptors[d].length = vt.inactiveWidth;
        descriptors[d].size = vt.inactiveWidth;
        descriptors[d].buf = cast(ubyte*) inactiveBuffer;
        d++;
        descriptors[d].length = vt.activeWidth;
        descriptors[d].size = vt.activeWidth;
        descriptors[d].buf = cast(ubyte*) frameBuffer[i / vt.vDiv];
        d++;
    }

    I2SManager i2sManager = I2SManager(1, vt.pixelClock, 8, pinMap, &descriptors[0]);

    while (true)
    {
        vTaskSuspend(null);
    }
}
