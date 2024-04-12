module app.i2s.i2s;

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

import core.volatile;

i2s_dev_t*[] i2sDevices = [&I2S0, &I2S1];

extern(C) alias FinishClockSetupCFuncType = void function(i2s_dev_t*);
extern(C) alias StartTransmittingCFuncType = void function(i2s_dev_t*, lldesc_t*);

FinishClockSetupCFuncType finishClockSetupCFunc;
StartTransmittingCFuncType startTransmittingCFunc;

struct I2SManager
{
private:
    uint i2sIndex;
    i2s_dev_t* i2sDev;
    uint bitCount;

public:
    this(
        uint i2sIndex,
        long freq, 
        uint bitCount,
        int[] pinMap,
        lldesc_t* firstDescriptor
    )
    in (finishClockSetupCFunc !is null && startTransmittingCFunc !is null)
    in (i2sIndex == 0 || i2sIndex == 1)
    in (bitCount == 8 || bitCount == 16)
    {
        this.i2sIndex = i2sIndex;
        this.i2sDev = i2sDevices[i2sIndex];
        this.bitCount = bitCount;

        routeSignalsToPins(pinMap);
        enable;
        reset;
        setupParallelOutput;
        setupClock(freq * 2 * (bitCount / 8));

        finishClockSetupCFunc(i2sDev);

	    i2sDev.conf.tx_right_first = 1; // high or low (stereo word order)
	    i2sDev.timing.val = 0;

        reset;

        startTransmittingCFunc(i2sDev, firstDescriptor);
    }

private:
    void routeSignalsToPins(in int[] pinMap)
    {
        immutable int[] signals = [I2S0O_DATA_OUT0_IDX, I2S1O_DATA_OUT0_IDX];

        for (int i = 0; i < bitCount; i++)
            if (pinMap[i] > -1)
            {
                ulong pin = GPIO_PIN_MUX_REG[pinMap[i]];
                ulong func = PIN_FUNC_GPIO;
                (*(cast(ulong*) pin)) = ((*(cast(ulong*) pin)) & ~(MCU_SEL_V << MCU_SEL_S)) | (
                    (func & MCU_SEL_V) << MCU_SEL_S);

                gpio_set_direction(cast(gpio_num_t) pinMap[i], cast(gpio_mode_t) GPIO_MODE_DEF_OUTPUT);
                if (i2sIndex == 1)
                {
                    if (bitCount == 16)
                        gpio_matrix_out(pinMap[i], signals[i2sIndex] + i + 8, false, false);
                    else
                        gpio_matrix_out(pinMap[i], signals[i2sIndex] + i, false, false);
                }
                else
                {
                    gpio_matrix_out(pinMap[i], signals[i2sIndex] + i + 24 - bitCount, false, false);
                }
            }
    }

    void enable()
    {
        immutable periph_module_t[] modules = [
            PERIPH_I2S0_MODULE, PERIPH_I2S1_MODULE
        ];
        periph_module_enable(modules[i2sIndex]);
    }

    void reset() pure
    {
        i2sDev.lc_conf.val |= 0xF;
        i2sDev.lc_conf.val &= ~0xF;
        i2sDev.conf.val |= 0xF;
        i2sDev.conf.val &= ~0xF;
        while (i2sDev.state.rx_fifo_reset_back)
        {
        }
    }

    void setupParallelOutput() pure
    {
        // Set parallel mode flags
        i2sDev.conf2.val = 0;
        i2sDev.conf2.lcd_en = 1;
        i2sDev.conf2.lcd_tx_wrx2_en = 1;
        i2sDev.conf2.lcd_tx_sdx2_en = 0;

        // Clear serial mode flags
        i2sDev.conf.tx_msb_right = 0;
        i2sDev.conf.tx_msb_shift = 0;
        i2sDev.conf.tx_mono = 0;
        i2sDev.conf.tx_short_sync = 0;
    }

    void setupClock(long freq)
    {
        i2sDev.sample_rate_conf.val = 0;
        i2sDev.sample_rate_conf.tx_bits_mod = bitCount;
        int sdm, sdmn;
        int odir = -1;
        do
        {
            odir++;
            sdm = cast(int)((cast(long)(
                    ((cast(double) freq) / (20_000_000.0 / (odir + 2))) * 0x10000)) - 0x40000);
            sdmn = cast(int)(
                (cast(long)(((cast(double) freq) / (20_000_000.0 / (odir + 2 + 1))) * 0x10000)) - 0x40000);
        }
        while (sdm < 0x8c0ecL && odir < 31 && sdmn < 0xA1fff);
        if (sdm > 0xA1fff)
            sdm = 0xA1fff;
        rtc_clk_apll_enable(true);
        rtc_clk_apll_coeff_set(odir, sdm & 255, (sdm >> 8) & 255, sdm >> 16);
    }
}
