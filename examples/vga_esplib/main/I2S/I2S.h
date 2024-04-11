#pragma once

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

#include "DMABufferDescriptor.h"

class I2S
{
// Instance fields
public:
    int i2sIndex;
    int dmaBufferDescriptorCount;
    DMABufferDescriptor *dmaBufferDescriptors;

// Instance methods
public:
    /// hardware index [0, 1]
    I2S(const int i2sIndex = 0);
    void reset();

    void stop();

    void i2sStop();
    void startTX();

    bool initParallelOutputMode(const int *pinMap, long APLLFreq = 1000000, const int bitCount = 8);
    DMABufferDescriptor *firstDescriptorAddress() const;

    void deleteDMABuffers();
};
