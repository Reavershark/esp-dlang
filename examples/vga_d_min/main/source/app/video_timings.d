module app.video_timings;

// dfmt off
@safe:

struct VideoTimings
{
// Nested types
public:
    struct Dimension
    {
        uint res, front, sync, back, polarity;
        uint total() const pure => res + front + sync + back;
        uint resStart() const pure => 0;
        uint resEnd() const pure => res;
        uint frontStart() const pure => res;
        uint frontEnd() const pure => res + front;
        uint syncStart() const pure => res + front;
        uint syncEnd() const pure => res + front + sync;
        uint backStart() const pure => res + front + sync;
        uint backEnd() const pure => res + front + sync + back;
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
    h: {res: 320, front: 8, sync: 48, back: 24, polarity: 1},
    v: {res: 480, front: 11, sync: 2, back: 31, polarity: 1},
    vDiv: 2,
    aspect: 1.0,
};
