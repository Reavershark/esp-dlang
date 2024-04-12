#include "rom/lldesc.h"
#include "soc/i2s_reg.h"
#include "soc/i2s_struct.h"

typedef unsigned char Color;

void finishClockSetupCFunc(volatile i2s_dev_t *i2s)
{
	int clockN = 2, clockA = 1, clockB = 0, clockDiv = 1;

	i2s->clkm_conf.val = 0;
	i2s->clkm_conf.clka_en = 1;
	i2s->clkm_conf.clkm_div_num = clockN;
	i2s->clkm_conf.clkm_div_a = clockA;
	i2s->clkm_conf.clkm_div_b = clockB;
	i2s->sample_rate_conf.tx_bck_div_num = clockDiv;
}

void startTransmittingCFunc(volatile i2s_dev_t *i2s, lldesc_t *dmaBufferDescriptors)
{
	i2s->lc_conf.val = I2S_OUT_DATA_BURST_EN | I2S_OUTDSCR_BURST_EN;
	i2s->out_link.addr = (uint32_t)&dmaBufferDescriptors[0];
	i2s->out_link.start = 1;
	i2s->conf.tx_start = 1;
}

extern void d_main(
	void finishClockSetupCFunc(volatile i2s_dev_t *i2s),
	void startTransmittingCFunc(i2s_dev_t *, lldesc_t *));

void app_main(void)
{
	d_main(&finishClockSetupCFunc, &startTransmittingCFunc);
}
