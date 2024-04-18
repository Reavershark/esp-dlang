module idf.esp_hw_support.port.soc.rtc;

@safe:

extern (C) @system
{
    void rtc_clk_apll_enable(bool enable);
    void rtc_clk_apll_coeff_set(uint o_div, uint sdm0, uint sdm1, uint sdm2);
}
