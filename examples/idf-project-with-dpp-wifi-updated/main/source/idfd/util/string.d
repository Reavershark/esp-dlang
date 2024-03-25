module idfd.util.string;

import std.traits : isSomeChar, isSomeString;

@safe:

enum string stringzOf(string s) = s ~ '\0';
enum immutable(char)* stringzPtrOf(string s) = (s ~ '\0').ptr;

enum string capitalized(string s) =
{
    auto res = s;
    if (s.length)
    {
        auto c = s[0];
        if ('a' <= c && c <= 'z')
            res = (c - 0x20) ~ s[1 .. $]; // Also correct when S.length == 1
    }
    return res;
}();

bool isAscii(C)(C c)
if (isSomeChar!C)
{
    return (c & 0x80) == 0;
}
