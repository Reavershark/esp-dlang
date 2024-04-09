#pragma once

#include "../I2S/I2S.h"
#include "Mode.h"

class VGA : public I2S
{
// Static fields
public:
    static const Mode MODE320x240;

// Instance fields
public:
    Mode mode;

protected:
    int lineBufferCount;
    int vsyncPin;
    int hsyncPin;
    int currentLine;
    long vsyncBit;
    long hsyncBit;
    long vsyncBitI;
    long hsyncBitI;

    int totalLines;
    volatile bool vSyncPassed;

    void *vSyncInactiveBuffer;
    void *vSyncActiveBuffer;
    void *inactiveBuffer;
    void *blankActiveBuffer;

// Instance methods
public:
    VGA(const int i2sIndex = 0);
    bool init(const Mode &mode, const int *pinMap, const int bitCount, const int clockPin = -1);
    virtual int bytesPerSample() const = 0;

protected:
    virtual void initSyncBits() = 0;
    virtual long syncBits(bool h, bool v) = 0;

    virtual void allocateLineBuffers() = 0;
    virtual void allocateLineBuffers(void **frameBuffer);
    virtual void propagateResolution(const int xres, const int yres) = 0;
};
