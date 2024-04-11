#define __builtin_ffs(arg) 0

#include "esp_heap_caps.h"
#include "soc/soc.h"
#include "soc/gpio_sig_map.h"
#include "soc/i2s_reg.h"
#include "soc/i2s_struct.h"
#include "soc/io_mux_reg.h"
#include "driver/gpio.h"
#include "driver/periph_ctrl.h"
#include "rom/lldesc.h"

#include "rom/gpio.h"
#include "soc/gpio_periph.h"

#include <soc/rtc.h>
#include <driver/rtc_io.h>

#include <stdio.h>

#define long(val) (cast(long)(val))
#define double(val) (cast(double)(val))

#define i2sIndex 1

void setPinFunction(uint32_t pin, uint32_t func)
{
    (*(volatile uint32_t *)pin) = ((*((volatile uint32_t *)pin)) & ~(MCU_SEL_V << MCU_SEL_S)) | ((func & MCU_SEL_V) << MCU_SEL_S);
}

i2s_dev_t *i2sDevices[] = {&I2S0, &I2S1};

bool init_parallel_output_mode()
{
    const int pinMap[] = {14, 27, 16, -1, -1, -1, 25, 26};
    const long sampleRate = 12587500;
    const int bitCount = 8;

    printf("%p\n", pinMap);
    printf("%d\n", sampleRate);
    printf("%d\n", bitCount);

	i2s_dev_t *i2s = i2sDevices[i2sIndex];
    printf("%p\n", i2s);

	//route peripherals
	//in parallel mode only upper 16 bits are interesting in this case
	const int deviceBaseIndex[] = {I2S0O_DATA_OUT0_IDX, I2S1O_DATA_OUT0_IDX};
	const periph_module_t deviceModule[] = {PERIPH_I2S0_MODULE, PERIPH_I2S1_MODULE};
	//works only since indices of the pads are sequential
	for (int i = 0; i < bitCount; i++)
		if (pinMap[i] > -1)
		{
            uint32_t pin = GPIO_PIN_MUX_REG[pinMap[i]];
            uint32_t func = PIN_FUNC_GPIO;
            (*(volatile uint32_t *)pin) = ((*((volatile uint32_t *)pin)) & ~(MCU_SEL_V << MCU_SEL_S)) | ((func & MCU_SEL_V) << MCU_SEL_S);

			gpio_set_direction((gpio_num_t)pinMap[i], (gpio_mode_t)GPIO_MODE_DEF_OUTPUT);
			//rtc_gpio_set_drive_capability((gpio_num_t)pinMap[i], (gpio_drive_cap_t)GPIO_DRIVE_CAP_3 );
			if(i2sIndex == 1)
			{
				if(bitCount == 16)
					gpio_matrix_out(pinMap[i], deviceBaseIndex[i2sIndex] + i + 8, false, false);
				else
					gpio_matrix_out(pinMap[i], deviceBaseIndex[i2sIndex] + i, false, false);
			}
			else
			{
				//there is something odd going on here in the two different I2S
				//the configuration seems to differ. Use i2s1 for high frequencies.
				gpio_matrix_out(pinMap[i], deviceBaseIndex[i2sIndex] + i + 24 - bitCount, false, false);
			}
		}

		//enable I2S peripheral
	periph_module_enable(deviceModule[i2sIndex]);

    // reset
	const unsigned long lc_conf_reset_flags = 0xF;
	i2s->lc_conf.val |= lc_conf_reset_flags;
	i2s->lc_conf.val &= ~lc_conf_reset_flags;

	const uint32_t conf_reset_flags = 0xF;
	i2s->conf.val |= conf_reset_flags;
	i2s->conf.val &= ~conf_reset_flags;
	while (i2s->state.rx_fifo_reset_back)
		;


	//parallel mode
	i2s->conf2.val = 0;
	i2s->conf2.lcd_en = 1;
	//from technical datasheet figure 64
	i2s->conf2.lcd_tx_wrx2_en = 1;
	i2s->conf2.lcd_tx_sdx2_en = 0;

	i2s->sample_rate_conf.val = 0;
	i2s->sample_rate_conf.tx_bits_mod = bitCount;
	//clock setup
	int clockN = 2, clockA = 1, clockB = 0, clockDiv = 1;
	if(sampleRate > 0)
	{
		//xtal is 40M
		//chip revision 0
		//fxtal * (sdm2 + 4) / (2 * (odir + 2))
		//chip revision 1
		//fxtal * (sdm2 + (sdm1 / 256) + (sdm0 / 65536) + 4) / (2 * (odir + 2))
		//fxtal * (sdm2 + (sdm1 / 256) + (sdm0 / 65536) + 4) needs to be btween 350M and 500M
		//rtc_clk_apll_enable(enable, sdm0, sdm1, sdm2, odir);
		//                           0-255 0-255  0-63  0-31
		//sdm seems to be simply a fixpoint number with 16bits fractional part
		//freq = 40000000L * (4 + sdm) / (2 * (odir + 2))
		//sdm = freq / (20000000L / (odir + 2)) - 4;
		long freq = sampleRate * 2 * (bitCount / 8);
		int sdm, sdmn;
		int odir = -1;
		do
		{	
			odir++;
            sdm = (int) (((long) ((((double) freq) / (20000000.0 / (odir + 2))) * 0x10000)) - 0x40000);
            sdmn = (int) (((long) ((((double) freq) / (20000000.0 / (odir + 2 + 1))) * 0x10000)) - 0x40000);
		}while(sdm < 0x8c0ecL && odir < 31 && sdmn < 0xA1fff); //0xA7fffL doesn't work on all mcus 
		//DEBUG_PRINTLN(sdm & 255);
		//DEBUG_PRINTLN((sdm >> 8) & 255);
		//DEBUG_PRINTLN(sdm >> 16);
		//DEBUG_PRINTLN(odir);
		//sdm = 0xA1fff;
		//odir = 0;
		if(sdm > 0xA1fff) sdm = 0xA1fff;
		rtc_clk_apll_enable(true);
		rtc_clk_apll_coeff_set(odir, sdm & 255, (sdm >> 8) & 255, sdm >> 16);
	}

	i2s->clkm_conf.val = 0;
	i2s->clkm_conf.clka_en = sampleRate > 0 ? 1 : 0;
	i2s->clkm_conf.clkm_div_num = clockN;
	i2s->clkm_conf.clkm_div_a = clockA;
	i2s->clkm_conf.clkm_div_b = clockB;
	i2s->sample_rate_conf.tx_bck_div_num = clockDiv;

	i2s->fifo_conf.val = 0;
	i2s->fifo_conf.tx_fifo_mod_force_en = 1;
	i2s->fifo_conf.tx_fifo_mod = 1;  //byte packing 0A0B_0B0C = 0, 0A0B_0C0D = 1, 0A00_0B00 = 3,
	i2s->fifo_conf.tx_data_num = 32; //fifo length
	i2s->fifo_conf.dscr_en = 1;		//fifo will use dma

	i2s->conf1.val = 0;
	i2s->conf1.tx_stop_en = 0;
	i2s->conf1.tx_pcm_bypass = 1;

	i2s->conf_chan.val = 0;
	i2s->conf_chan.tx_chan_mod = 1;

	//high or low (stereo word order)
	i2s->conf.tx_right_first = 1;

	i2s->timing.val = 0;

	//clear serial mode flags
	i2s->conf.tx_msb_right = 0;
	i2s->conf.tx_msb_shift = 0;
	i2s->conf.tx_mono = 0;
	i2s->conf.tx_short_sync = 0;

	return true;
}

void start_tx(const lldesc_t *firstDescriptorAddress)
{
	i2s_dev_t *i2s = i2sDevices[i2sIndex];

	const unsigned long lc_conf_reset_flags = 0xF;
	i2s->lc_conf.val |= lc_conf_reset_flags;
	i2s->lc_conf.val &= ~lc_conf_reset_flags;

	const uint32_t conf_reset_flags = 0xF;
	i2s->conf.val |= conf_reset_flags;
	i2s->conf.val &= ~conf_reset_flags;
	while (i2s->state.rx_fifo_reset_back)
		;

    i2s->lc_conf.val    = I2S_OUT_DATA_BURST_EN | I2S_OUTDSCR_BURST_EN;
	i2s->out_link.addr = (uint32_t)firstDescriptorAddress;
	i2s->out_link.start = 1;
	i2s->conf.tx_start = 1;
}