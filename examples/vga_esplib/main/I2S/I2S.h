#pragma once

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
    int dmaBufferDescriptorActive;
    DMABufferDescriptor *dmaBufferDescriptors;
    volatile bool stopSignal;

// Instance methods
public:
    /// hardware index [0, 1]
    I2S(const int i2sIndex = 0);
    void reset();

    void stop();

    void i2sStop();
    void startTX();
    void startRX();

    void resetDMA();
    void resetFIFO();
    bool initParallelOutputMode(const int *pinMap, long APLLFreq = 1000000, const int bitCount = 8, int wordSelect = -1, int baseClock = -1);
    bool initSerialOutputMode(int dataPin, const int bitCount = 8, int wordSelect = -1, int baseClock = -1);
    bool initParallelInputMode(const int *pinMap, long sampleRate = 1000000, const int bitCount = 8, int wordSelect = -1, int baseClock = -1);
    DMABufferDescriptor *firstDescriptorAddress() const;

    void allocateDMABuffers(int count, int bytes);
    void deleteDMABuffers();
    void getClockSetting(long *sampleRate, int *n, int *a, int *b, int *div);

  protected:
    void setAPLLClock(long sampleRate, int bitCount);
    void setClock(long sampleRate, int bitCount, bool useAPLL = true);
};
