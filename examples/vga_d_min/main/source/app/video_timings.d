module app.video_timings;

// dfmt off
@safe:

struct VideoTimings
{
// Nested types
public:
    struct Dimension
    {
        uint front, sync, back, res, polarity;
        uint total() const pure => front + sync + back + res;
    }

// Instance fields
public:
    ulong pixelClock;
    Dimension h;
    Dimension v;
    uint vDiv; // Affects framebuffer height
    float aspect;

// Instance methods
public:
    uint activeWidth() const pure => h.res;
    uint inactiveWidth() const pure => h.front + h.sync + h.back;
    uint activeHeight() const pure => v.res / vDiv;
}

immutable VideoTimings videoTimings320x480 = {
    pixelClock: 12_587_500,
    h: {front: 8, sync: 48, back: 24, res: 320, polarity: 1},
    v: {front: 11, sync: 2, back: 31, res: 480, polarity: 1},
    vDiv: 2,
    aspect: 1.0,
};
