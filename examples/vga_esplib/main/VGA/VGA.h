#pragma once

#include "../I2S/I2S.h"
#include "Mode.h"

typedef unsigned char Color;

class VGA : public I2S
{
// Static fields
public:
    static const Mode MODE320x240;

// Instance fields
private:
    Mode mode;

    int totalLines;

    long vsyncBit;
    long hsyncBit;
    long vsyncBitI;
    long hsyncBitI;

    void *vSyncInactiveBuffer;
    void *vSyncActiveBuffer;
    void *inactiveBuffer;
    void *blankActiveBuffer;
    Color **frameBuffer;

// Instance methods
public:
    VGA(const int i2sIndex = 0);
    bool init(const Mode &mode, const int *pinMap, const int bitCount);

private:
    void allocateLineBuffers(void **frameBuffer);
};
