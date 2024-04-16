module idfd.signalio.gpio;

import idfd.signalio.signal : Signal;

struct GPIOPin
{
    enum FIRST_PIN = 0;
    enum LAST_PIN = 39;

    private uint m_pin;

    @disable this();

    this(uint pin)
    in (FIRST_PIN <= pin && pin <= LAST_PIN)
    {
        m_pin = pin;
    }

    uint pin() pure const => m_pin;
    bool supportsInput() pure const => true;
    bool supportsOutput() pure const => pin <= 33;
}
