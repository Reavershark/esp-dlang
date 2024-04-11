#include "VGA.h"

// hfront hsync hback pixels vfront vsync vback lines divy pixelclock hpolaritynegative vpolaritynegative
const Mode VGA::MODE320x240(8, 48, 24, 320, 11, 2, 31, 480, 2, 12587500, 1, 1);

VGA::VGA(const int i2sIndex)
    : I2S(i2sIndex)
{
}

bool VGA::init(const Mode &mode, const int *pinMap, const int bitCount)
{
    this->mode = mode;
    int xres = mode.hRes;
    int yres = mode.vRes / mode.vDiv;

    hsyncBitI = mode.hSyncPolarity ? 0x40 : 0; // <= 0x40
    vsyncBitI = mode.vSyncPolarity ? 0x80 : 0; // <= 0x80
    hsyncBit = hsyncBitI ^ 0x40;
    vsyncBit = vsyncBitI ^ 0x80;

    frameBuffer = (Color **) DMABufferDescriptor::allocateDMABufferArray(
        yres,
        mode.hRes,
        true,
        0xC1C1C1C1
    );

    totalLines = mode.linesPerField();
    allocateLineBuffers((void **) frameBuffer);
    initParallelOutputMode(pinMap, mode.pixelClock, bitCount);
    startTX();

    return true;
}

///complete ringbuffer from frame
void VGA::allocateLineBuffers(void **frameBuffer)
{
    dmaBufferDescriptorCount = totalLines * 2;
    int inactiveSamples = mode.hFront + mode.hSync + mode.hBack;
    inactiveBuffer = DMABufferDescriptor::allocateBuffer(inactiveSamples, true);
    vSyncInactiveBuffer = DMABufferDescriptor::allocateBuffer(inactiveSamples, true);
    blankActiveBuffer = DMABufferDescriptor::allocateBuffer(mode.hRes, true);
    vSyncActiveBuffer = DMABufferDescriptor::allocateBuffer(mode.hRes, true);

    for (int i = 0; i < inactiveSamples; i++)
    {
        if (mode.hFront <= i && i < mode.hFront + mode.hSync)
        {
            ((unsigned char *)vSyncInactiveBuffer)[i ^ 2] = 0;
            ((unsigned char *)inactiveBuffer)[i ^ 2] = 0x80;
        }
        else
        {
            ((unsigned char *)vSyncInactiveBuffer)[i ^ 2] = 0x40;
            ((unsigned char *)inactiveBuffer)[i ^ 2] = 0xC0;
        }
    }
    for (int i = 0; i < mode.hRes; i++)
    {
        ((unsigned char *)blankActiveBuffer)[i ^ 2] = 0xC0;
        ((unsigned char *)vSyncActiveBuffer)[i ^ 2] = 0x40;
    }

    dmaBufferDescriptors = DMABufferDescriptor::allocateDescriptors(dmaBufferDescriptorCount);

    for (int i = 0; i < dmaBufferDescriptorCount; i++)
        dmaBufferDescriptors[i].next(dmaBufferDescriptors[(i + 1) % dmaBufferDescriptorCount]);

    int d = 0;
    for (int i = 0; i < mode.vFront; i++)
    {
        dmaBufferDescriptors[d++].setBuffer(inactiveBuffer, inactiveSamples);
        dmaBufferDescriptors[d++].setBuffer(blankActiveBuffer, mode.hRes);
    }
    for (int i = 0; i < mode.vSync; i++)
    {
        dmaBufferDescriptors[d++].setBuffer(vSyncInactiveBuffer, inactiveSamples);
        dmaBufferDescriptors[d++].setBuffer(vSyncActiveBuffer, mode.hRes);
    }
    for (int i = 0; i < mode.vBack; i++)
    {
        dmaBufferDescriptors[d++].setBuffer(inactiveBuffer, inactiveSamples);
        dmaBufferDescriptors[d++].setBuffer(blankActiveBuffer, mode.hRes);
    }
    for (int i = 0; i < mode.vRes; i++)
    {
        dmaBufferDescriptors[d++].setBuffer(inactiveBuffer, inactiveSamples);
        dmaBufferDescriptors[d++].setBuffer(frameBuffer[i / mode.vDiv], mode.hRes);
    }
}
