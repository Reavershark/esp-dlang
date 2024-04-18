module idfd.signalio.i2s;

import idfd.signalio.signal : Signal;
import idfd.util;

import idf.esp_hw_support.esp_private.periph_ctrl : periph_module_enable;
import idf.esp_hw_support.port.soc.rtc : rtc_clk_apll_coeff_set, rtc_clk_apll_enable;
import idf.esp_rom.lldesc : lldesc_t;
import idf.soc.gpio_sig_map : I2S0O_DATA_OUT0_IDX, I2S1O_DATA_OUT0_IDX;
import idf.soc.i2s_struct : I2S0, I2S1, i2s_dev_t;
import idf.soc.periph_defs : PERIPH_I2S0_MODULE, PERIPH_I2S1_MODULE, periph_module_t;

import ldc.attributes : optStrategy;

@safe:

i2s_dev_t*[] i2sDevices = [&I2S0, &I2S1];

extern (C) alias FinishClockSetupCFuncType = void function(i2s_dev_t*);
extern (C) alias StartTransmittingCFuncType = void function(i2s_dev_t*, lldesc_t*);

shared FinishClockSetupCFuncType finishClockSetupCFunc;
shared StartTransmittingCFuncType startTransmittingCFunc;

extern(C) void linkI2SCFuncs(
    FinishClockSetupCFuncType finishClockSetupCFunc,
    StartTransmittingCFuncType startTransmittingCFunc
)
{
    .finishClockSetupCFunc = finishClockSetupCFunc;
    .startTransmittingCFunc = startTransmittingCFunc;
}

struct I2SSignalGenerator
{
@optStrategy("none"):
    private uint m_i2sIndex;
    private i2s_dev_t* m_i2sDev;
    private uint m_bitCount;

    /** 
     * Params:
     *   bitCount = Number of bits in one sample.
     *              This is equal to the number of generated signals.
     *   freq = Bit speed/frequency on each pin.
     *   i2sIndex = Which of the 2 I2S devices to use: `0` or `1`.
     */
    this(
        uint i2sIndex,
        uint bitCount,
        long freq,
    )
    in (finishClockSetupCFunc !is null && startTransmittingCFunc !is null)
    in (bitCount == 8 || bitCount == 16)
    in (i2sIndex == 0 || i2sIndex == 1)
    {
        m_i2sIndex = i2sIndex;
        m_bitCount = bitCount;
        m_i2sDev = i2sDevices[m_i2sIndex];

        enable;
        reset;
        setupParallelOutput;
        setupClock(freq * 2 * (m_bitCount / 8));
        prepareForTransmitting;
        reset;
    }

    private void enable()
    {
        immutable periph_module_t[] modules = [
            PERIPH_I2S0_MODULE, PERIPH_I2S1_MODULE
        ];
        const periph_module_t m = modules[m_i2sIndex];
        (() @trusted => periph_module_enable(m))();
    }

    private void reset() pure
    {
        m_i2sDev.lc_conf.val |= 0xF;
        m_i2sDev.lc_conf.val &= ~0xF;
        m_i2sDev.conf.val |= 0xF;
        m_i2sDev.conf.val &= ~0xF;
        while (m_i2sDev.state.rx_fifo_reset_back)
        {
        }
    }

    private void setupParallelOutput() pure
    {
        // Set parallel mode flags
        m_i2sDev.conf2.val = 0;
        m_i2sDev.conf2.lcd_en = 1;
        m_i2sDev.conf2.lcd_tx_wrx2_en = 1;
        m_i2sDev.conf2.lcd_tx_sdx2_en = 0;

        // Clear serial mode flags
        m_i2sDev.conf.tx_msb_right = 0;
        m_i2sDev.conf.tx_msb_shift = 0;
        m_i2sDev.conf.tx_mono = 0;
        m_i2sDev.conf.tx_short_sync = 0;
    }

    private void setupClock(long freq)
    {
        m_i2sDev.sample_rate_conf.val = 0;
        m_i2sDev.sample_rate_conf.tx_bits_mod = m_bitCount;
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

        () @trusted {
            rtc_clk_apll_enable(true);
            rtc_clk_apll_coeff_set(odir, sdm & 255, (sdm >> 8) & 255, sdm >> 16);
        }();

        finishClockSetupCFunc(m_i2sDev);
    }

    private void prepareForTransmitting() pure
    {
        m_i2sDev.fifo_conf.val = 0;
        m_i2sDev.fifo_conf.tx_fifo_mod_force_en = 1;
        m_i2sDev.fifo_conf.tx_fifo_mod = 1; //byte packing 0A0B_0B0C = 0, 0A0B_0C0D = 1, 0A00_0B00 = 3,
        m_i2sDev.fifo_conf.tx_data_num = 32; //fifo length
        m_i2sDev.fifo_conf.dscr_en = 1; //fifo will use dma

        m_i2sDev.conf1.val = 0;
        m_i2sDev.conf1.tx_stop_en = 0;
        m_i2sDev.conf1.tx_pcm_bypass = 1;

        m_i2sDev.conf_chan.val = 0;
        m_i2sDev.conf_chan.tx_chan_mod = 1;

        m_i2sDev.conf.tx_right_first = 1; // high or low (stereo word order)
        m_i2sDev.timing.val = 0;
    }

    // Todo: Should return refcounted
    UniqueHeapArray!Signal getSignals() const
    {
        Signal[] signals = dallocArray!Signal(m_bitCount);

        foreach (i, ref signal; signals)
        {
            final switch (m_i2sIndex)
            {
            case 0:
                immutable int baseIndex = I2S0O_DATA_OUT0_IDX;
                signal = Signal(baseIndex + 24 - m_bitCount + i);
                break;
            case 1:
                immutable int baseIndex = I2S1O_DATA_OUT0_IDX;
                if (m_bitCount == 16)
                    signal = Signal(baseIndex + 8 + i);
                else
                    signal = Signal(baseIndex + i);
                break;
            }
        }
        return UniqueHeapArray!Signal(move(signals));
    }

    /** 
     * Params:
     *   firstDescriptor = Pointer to a lldesc_t of which the next ptr can be followed infinitely.
     */
    void startTransmitting(lldesc_t* firstDescriptor)
    {
        startTransmittingCFunc(m_i2sDev, firstDescriptor);
    }
}
