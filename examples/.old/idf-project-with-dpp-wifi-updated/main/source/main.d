module main;

import idf.driver.i2s_std;
import idf.esp_err : ESP_OK;
import idfd.freertos;

alias size_t = object.size_t;

i2s_chan_handle_t tx_chan;

extern(C)
void app_main() @trusted
{
    init_tx_chan();

    xTaskCreate(tx_chan_write_task, "tx_chan_write_task", 4096, null, 5, null);
}

void init_tx_chan()
{
    i2s_chan_config_t tx_chan_cfg = {
        id : i2s_port_t.I2S_NUM_AUTO,
        role : i2s_role_t.I2S_ROLE_MASTER,
        dma_desc_num : 6,
        dma_frame_num : 240,
        auto_clear : false,
        intr_priority : 0,
    };

    i2s_std_config_t tx_std_cfg = {
        clk_cfg : {
            sample_rate_hz : 16000,
            clk_src : soc_periph_i2s_clk_src_t.I2S_CLK_SRC_DEFAULT,
            mclk_multiple : i2s_mclk_multiple_t.I2S_MCLK_MULTIPLE_256,
        },
        slot_cfg : {
            data_bit_width : i2s_data_bit_width_t.I2S_DATA_BIT_WIDTH_16BIT,
            slot_bit_width : i2s_slot_bit_width_t.I2S_SLOT_BIT_WIDTH_AUTO,
            slot_mode : i2s_slot_mode_t.I2S_SLOT_MODE_MONO,
            slot_mask : i2s_std_slot_mask_t.I2S_STD_SLOT_LEFT,
            ws_width : i2s_data_bit_width_t.I2S_DATA_BIT_WIDTH_16BIT,
            ws_pol : false,
            bit_shift : false,
            msb_right : true,
        },
        gpio_cfg : {
            mclk : gpio_num_t.GPIO_NUM_NC, // some codecs may require mclk signal, this example doesn't need it
            bclk : gpio_num_t.GPIO_NUM_4,  // I2S bit clock io number
            ws   : gpio_num_t.GPIO_NUM_5,  // I2S word select io number
            dout : gpio_num_t.GPIO_NUM_18, // I2S data out io number
            din  : gpio_num_t.GPIO_NUM_19, // I2S data in io number
        },
    };
    tx_std_cfg.invert_flags.mclk_inv = false;
    tx_std_cfg.invert_flags.bclk_inv = false;
    tx_std_cfg.invert_flags.ws_inv = false;

    if (i2s_new_channel(&tx_chan_cfg, &tx_chan, null) != ESP_OK)
        assert(false);

    if (i2s_channel_init_std_mode(tx_chan, &tx_std_cfg) != ESP_OK)
        assert(false);
}

enum EXAMPLE_BUFF_SIZE = 2048;

extern (C)
void tx_chan_write_task(void* args)
{
    ubyte* w_buf = cast(ubyte*) calloc(1, EXAMPLE_BUFF_SIZE);
    assert(w_buf); // Check if w_buf allocation success

    /* Assign w_buf */
    for (int i = 0; i < EXAMPLE_BUFF_SIZE; i += 8) {
        w_buf[i]     = 0x12;
        w_buf[i + 1] = 0x34;
        w_buf[i + 2] = 0x56;
        w_buf[i + 3] = 0x78;
        w_buf[i + 4] = 0x9A;
        w_buf[i + 5] = 0xBC;
        w_buf[i + 6] = 0xDE;
        w_buf[i + 7] = 0xF0;
    }

    size_t w_bytes = EXAMPLE_BUFF_SIZE;

    /* (Optional) Preload the data before enabling the TX channel, so that the valid data can be transmitted immediately */
    while (w_bytes == EXAMPLE_BUFF_SIZE) {
        /* Here we load the target buffer repeatedly, until all the DMA buffers are preloaded */
        if (i2s_channel_preload_data(tx_chan, w_buf, EXAMPLE_BUFF_SIZE, &w_bytes) != ESP_OK)
            assert(false);
    }

    /* Enable the TX channel */
    if(i2s_channel_enable(tx_chan) != ESP_OK)
        assert(false);

    while (true)
    {
        /* Write i2s data */
        if (i2s_channel_write(tx_chan, w_buf, EXAMPLE_BUFF_SIZE, &w_bytes, 1000) == ESP_OK)
            printf("Write Task: i2s write %d bytes\n", w_bytes);
        else
            printf("Write Task: i2s write failed\n");
        vTaskDelay(200.msecs);
    }

    free(w_buf);
    vTaskDelete(null);
}
