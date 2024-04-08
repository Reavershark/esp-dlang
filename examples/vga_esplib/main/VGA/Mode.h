#pragma once

class Mode
{
public:
    int hFront, hSync, hBack, hRes;
    int vFront, vSync, vBack, vRes;
    int vDiv;
    unsigned long pixelClock;
    int hSyncPolarity;
    int vSyncPolarity;
    float aspect;
    int activeLineCount;

    Mode(
        const int hFront = 0, const int hSync = 0, const int hBack = 0, const int hRes = 0,
        const int vFront = 0, const int vSync = 0, const int vBack = 0, const int vRes = 0,
        const int vDiv = 1,
        const unsigned long pixelClock = 0,
        const int hSyncPolarity = 1,
        const int vSyncPolarity = 1,
        const float aspect = 1.f
    ) :
        hFront(hFront), hSync(hSync), hBack(hBack), hRes(hRes),
        vFront(vFront), vSync(vSync), vBack(vBack), vRes(vRes),
        vDiv(vDiv),
        pixelClock(pixelClock),
        hSyncPolarity(hSyncPolarity),
        vSyncPolarity(vSyncPolarity),
        aspect(aspect),
        activeLineCount(vRes / vDiv)
    {
    }

    int linesPerField() const
    {
        return vFront + vSync + vBack + vRes;
    }

    int pixelsPerLine() const
    {
        return hFront + hSync + hBack + hRes;
    }
};
