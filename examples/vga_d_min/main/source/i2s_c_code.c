#include "rom/lldesc.h"
#include "soc/i2s_reg.h"
#include "soc/i2s_struct.h"

typedef unsigned char Color;

void finishClockSetupCFunc(volatile i2s_dev_t* i2s)
{
	int clockN = 2, clockA = 1, clockB = 0, clockDiv = 1;

	i2s->clkm_conf.val = 0;
	i2s->clkm_conf.clka_en = 1;
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
}

void startTransmittingCFunc(volatile i2s_dev_t* i2s, lldesc_t* dmaBufferDescriptors)
{
    i2s->lc_conf.val   = (1UL << 11) | (1UL << 9);
	i2s->out_link.addr = (uint32_t)&dmaBufferDescriptors[0];
	i2s->out_link.start = 1;
	i2s->conf.tx_start = 1;
}

extern void d_main(
	void finishClockSetupCFunc(volatile i2s_dev_t* i2s),
	void startTransmittingCFunc(i2s_dev_t *, lldesc_t *)
);

void app_main(void)
{
    d_main(
		&finishClockSetupCFunc,
		&startTransmittingCFunc
	);
}
