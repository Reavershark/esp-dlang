module app.video_timings;

// dfmt off
@safe:

struct VideoTimings
{
    struct Dimension
    {
        uint res, front, sync, back;
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

    ulong pixelClock;
    Dimension h;
    Dimension v;
}

immutable VideoTimings videoTimings320x480 = {
    pixelClock: 12_587_500,
    h: {res: 320, front: 8, sync: 48, back: 24},
    v: {res: 480, front: 11, sync: 2, back: 31},
};
