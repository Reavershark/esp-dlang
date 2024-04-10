module app.i2s_manager;

import idf.esp_driver_gpio.gpio : gpio_set_direction;
import idf.esp_hw_support.esp_private.periph_ctrl : periph_module_enable;
import idf.esp_hw_support.port.soc.rtc : rtc_clk_apll_coeff_set, rtc_clk_apll_enable;
import idf.esp_rom.gpio : gpio_matrix_out;
import idf.esp_rom.lldesc : lldesc_t;
import idf.hal.gpio_types : GPIO_MODE_DEF_OUTPUT, gpio_mode_t;
import idf.soc.gpio_num : gpio_num_t;
import idf.soc.gpio_periph : GPIO_PIN_MUX_REG;
import idf.soc.i2s_struct : I2S0, I2S1, i2s_dev_t;
import idf.soc.io_mux_reg : PIN_FUNC_GPIO, setPinFunction;
import idf.soc.periph_defs : PERIPH_I2S0_MODULE, PERIPH_I2S1_MODULE, periph_module_t;

import idf.soc.gpio_sig_map;
import idf.soc.i2s_reg;

// dfmt off
@safe:

private
{
    i2s_dev_t*[] i2sDevices = [&I2S0, &I2S1];
    immutable(periph_module_t)[] i2sPeripheralModules = [PERIPH_I2S0_MODULE, PERIPH_I2S1_MODULE];
    immutable(uint[]) i2sOutSignalIndices = [I2S0O_DATA_OUT0_IDX, I2S1O_DATA_OUT0_IDX];
}

struct I2SManager
{
// Instance fields
private:
    const uint i2sIndex;
    const lldesc_t* firstDMADescriptor;

    i2s_dev_t* i2sDev;

// Instance methods
public:
    this(const uint i2sIndex, in int[] pinMap, const long sampleRate, const lldesc_t* firstDMADescriptor)
    in (i2sIndex < i2sPeripheralModules.length)
    {
        this.i2sIndex = i2sIndex;
        this.firstDMADescriptor = firstDMADescriptor;
        i2sDev = i2sDevices[i2sIndex];

        enablePeripheralModule;
        setupParallelOutput(pinMap, sampleRate);
        startTransmitting;
    }

private:
    auto i2sPeripheralModule() const => i2sPeripheralModules[i2sIndex];
    auto i2sOutSignalIndex() const => i2sOutSignalIndices[i2sIndex];

    void enablePeripheralModule() const @trusted
    {
        periph_module_enable(i2sPeripheralModule);
    }

    void resetModule() pure
    {
        // Set and unset in_rst, out_rst, ahmb_fifo_rst, ahbm_rst
        const ulong lc_conf_reset_flags = 0xF;
        i2sDev.lc_conf.val |= lc_conf_reset_flags;
        i2sDev.lc_conf.val &= ~lc_conf_reset_flags;

        // Set and unset tx_reset, rx_reset, tx_fifo_reset, rx_fifo_reset
        const uint conf_reset_flags = 0xF;
        i2sDev.conf.val |= conf_reset_flags;
        i2sDev.conf.val &= ~conf_reset_flags;

        // Wait on the module to finish
        while (i2sDev.state.rx_fifo_reset_back) {}
    }

    void setupParallelOutput(in int[] pinMap, const long sampleRate)
    in (pinMap.length == 8)
    in (sampleRate > 0)
    {
        const size_t bitCount = pinMap.length;

        foreach (i, pin; pinMap)
            if (pin > -1)
            {
                () @trusted {
                    setPinFunction(GPIO_PIN_MUX_REG[pin], PIN_FUNC_GPIO);
                    gpio_set_direction(cast(gpio_num_t) pin, cast(gpio_mode_t) GPIO_MODE_DEF_OUTPUT);
                    if (i2sIndex == 1)
                    {
                        if (bitCount == 16)
                            gpio_matrix_out(pin, i2sOutSignalIndex + i + 8, false, false);
                        else
                            gpio_matrix_out(pin, i2sOutSignalIndex + i, false, false);
                    }
                    else
                    {
                        gpio_matrix_out(pin, i2sOutSignalIndex + i + 24 - bitCount, false, false);
                    }
                }();
            }

        // Why not regular reset()?
        i2sDev.conf.tx_reset = 1;
        i2sDev.conf.tx_reset = 0;
        i2sDev.conf.rx_reset = 1;
        i2sDev.conf.rx_reset = 0;
        i2sDev.conf.rx_fifo_reset = 1;
        i2sDev.conf.rx_fifo_reset = 0;
        i2sDev.conf.tx_fifo_reset = 1;
        i2sDev.conf.tx_fifo_reset = 0;
        i2sDev.lc_conf.in_rst = 1;
        i2sDev.lc_conf.in_rst = 0;
        i2sDev.lc_conf.out_rst = 1;
        i2sDev.lc_conf.out_rst = 0;

        i2sDev.conf2.val = 0;
        i2sDev.conf2.lcd_en = 1;
        i2sDev.conf2.lcd_tx_wrx2_en = 1;
        i2sDev.conf2.lcd_tx_sdx2_en = 0;

        i2sDev.sample_rate_conf.val = 0;
        i2sDev.sample_rate_conf.tx_bits_mod = bitCount;
        int clockN = 2, clockA = 1, clockB = 0, clockDiv = 1;

        if (sampleRate > 0)
        {
            long freq = sampleRate * 2 * (bitCount / 8);
            int sdm, sdmn;
            int odir = -1;
            do
            {	
                odir++;
                sdm = cast(int) ((cast(long) (((cast(double) freq) / (20_000_000.0 / (odir + 2))) * 0x10000)) - 0x40000);
                sdmn = cast(int) ((cast(long) (((cast(double) freq) / (20_000_000.0 / (odir + 2 + 1))) * 0x10000)) - 0x40000);
            }
            while (sdm < 0x8c0ecL && odir < 31 && sdmn < 0xA1fff);
            if (sdm > 0xA1fff)
                sdm = 0xA1fff;
            () @trusted {
                rtc_clk_apll_enable(true);
                rtc_clk_apll_coeff_set(odir, sdm & 255, (sdm >> 8) & 255, sdm >> 16);
            } ();
        }

        i2sDev.clkm_conf.val = 0;
        i2sDev.clkm_conf.clka_en = sampleRate > 0 ? 1 : 0;
        i2sDev.clkm_conf.clkm_div_num = clockN;
        i2sDev.clkm_conf.clkm_div_a = clockA;
        i2sDev.clkm_conf.clkm_div_b = clockB;
        i2sDev.sample_rate_conf.tx_bck_div_num = clockDiv;

        i2sDev.fifo_conf.val = 0;
        i2sDev.fifo_conf.tx_fifo_mod_force_en = 1;
        i2sDev.fifo_conf.tx_fifo_mod = 1;
        i2sDev.fifo_conf.tx_data_num = 32;
        i2sDev.fifo_conf.dscr_en = 1;

        i2sDev.conf1.val = 0;
        i2sDev.conf1.tx_stop_en = 0;
        i2sDev.conf1.tx_pcm_bypass = 1;

        i2sDev.conf_chan.val = 0;
        i2sDev.conf_chan.tx_chan_mod = 1;

        i2sDev.conf.tx_right_first = 1;

        i2sDev.timing.val = 0;

        // Clear serial mode flags
        i2sDev.conf.tx_msb_right = 0;
        i2sDev.conf.tx_msb_shift = 0;
        i2sDev.conf.tx_mono = 0;
        i2sDev.conf.tx_short_sync = 0;
    }

    void startTransmitting()
    {
        resetModule;
        i2sDev.lc_conf.val = (1 << 11) | (1 << 9); // I2S_OUT_DATA_BURST_EN | I2S_OUTDSCR_BURST_EN
        i2sDev.out_link.addr = cast(uint) firstDMADescriptor;
        i2sDev.out_link.start = 1;
        i2sDev.conf.tx_start = 1;
    }
}
