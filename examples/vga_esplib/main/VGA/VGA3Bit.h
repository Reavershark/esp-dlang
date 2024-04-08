#pragma once

#include "VGA.h"
#include "../Graphics/GraphicsR1G1B1A1X2S2Swapped.h"

class VGA3Bit : public VGA, public GraphicsR1G1B1A1X2S2Swapped
{
// Instance fields
public:
	void *vSyncInactiveBuffer;
	void *vSyncActiveBuffer;
	void *inactiveBuffer;
	void *blankActiveBuffer;

// Instance methods
public:
	VGA3Bit() : VGA(1) // 8 bit based modes only work with I2S1
	{
	}

	bool init(
        const Mode &mode,
        const int redPin,
        const int greenPin,
        const int bluePin,
        const int hsyncPin,
        const int vsyncPin,
        const int clockPin = -1
    )
	{
		int pinMap[8] = {
			redPin,
			greenPin,
			bluePin,
			-1,
            -1,
            -1,
			hsyncPin,
            vsyncPin
		};
		return VGA::init(mode, pinMap, 8, clockPin);
	}

	virtual void initSyncBits() override // Overrides VGA::initSyncBits
	{
		hsyncBitI = mode.hSyncPolarity ? 0x40 : 0;
		vsyncBitI = mode.vSyncPolarity ? 0x80 : 0;
		hsyncBit = hsyncBitI ^ 0x40;
		vsyncBit = vsyncBitI ^ 0x80;
		SBits = hsyncBitI | vsyncBitI;
	}
		
	virtual long syncBits(bool hSync, bool vSync) override // Overrides VGA::syncBits
	{
		return ((hSync ? hsyncBit : hsyncBitI) | (vSync ? vsyncBit : vsyncBitI)) * 0x1010101;
	}

	virtual int bytesPerSample() const override // Overrides VGA::bytesPerSample
	{
		return 1;
	}

	virtual float pixelAspect() const override // Overrides Graphics::pixelAspect
	{
		return 1;
	}

	virtual void propagateResolution(const int xres, const int yres) override // Overrides VGA::propagateResolution
	{
		setResolution(xres, yres);
	}

    virtual Color **allocateFrameBuffer() override // Overrides Graphics::allocateFrameBuffer
	{
		return (Color **)DMABufferDescriptor::allocateDMABufferArray(yres, mode.hRes * bytesPerSample(), true, syncBits(false, false));
	}

	virtual void allocateLineBuffers() override // Overrides VGA::allocateLineBuffers()
	{
		VGA::allocateLineBuffers((void **)frameBuffers[0]);
	}

	virtual void show(bool vSync = false) override // Overrides Graphics::show
	{
		if (!frameBufferCount)
			return;
		if (vSync)
		{
			//TODO read the I2S docs to find out
		}
		Graphics::show(vSync);
		if(dmaBufferDescriptors)
		for (int i = 0; i < yres * mode.vDiv; i++)
			dmaBufferDescriptors[(mode.vFront + mode.vSync + mode.vBack + i) * 2 + 1].setBuffer(frontBuffer[i / mode.vDiv], mode.hRes * bytesPerSample());
	}

	virtual void scroll(int dy, Color color) override // Overrides Graphics::scroll
	{
		Graphics::scroll(dy, color);
		if (frameBufferCount == 1)
			show();
	}
};
