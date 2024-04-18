module app.color;

@safe:
// dfmt off

struct Color
{
    ubyte m_value;

    enum Color BLACK   = Color(0);
    enum Color RED     = Color(1 << 0);
    enum Color GREEN   = Color(1 << 1);
    enum Color BLUE    = Color(1 << 2);
    enum Color YELLOW  = RED | GREEN;
    enum Color MAGENTA = RED | BLUE;
    enum Color CYAN    = GREEN | BLUE;
    enum Color WHITE   = RED | GREEN | BLUE;

    enum Color BLANK   = BLACK;
    enum Color HSYNC   = Color(1 << 6);
    enum Color VSYNC   = Color(1 << 7);

    alias m_value this;

    auto opBinary(string op)(const Color rhs) const
    {
        return mixin("Color(m_value " ~ op ~ " rhs.m_value)");
    }
}