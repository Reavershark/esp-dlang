#pragma once

#include "../I2S/I2S.h"
#include "Mode.h"

class VGA : public I2S
{
  public:
	VGA(const int i2sIndex = 0);
	void setLineBufferCount(int lineBufferCount);
	bool init(const Mode &mode, const int *pinMap, const int bitCount, const int clockPin = -1);

	static const Mode MODE320x240;

	Mode mode;

	virtual int bytesPerSample() const = 0;

  protected:
	virtual void initSyncBits() = 0;
	virtual long syncBits(bool h, bool v) = 0;
 
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

	void allocateLineBuffers(const int lines);
	virtual void allocateLineBuffers();
	virtual void allocateLineBuffers(void **frameBuffer);
	virtual void propagateResolution(const int xres, const int yres) = 0;
};
