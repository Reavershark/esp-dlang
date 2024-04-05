module idfd.utils.string;

@safe:

enum string StringzOf(string S) = (S ~ '\0');
enum immutable(char)* StringzPtrOf(string S) = (S ~ '\0').ptr;

enum bool IsAscii(char c) = (c & 0x80) == 0;

enum string Capitalized(string S) =
{
    static if (S.length >= 1)
    {
        enum C = S[0];
        static assert(IsAscii!C, "First letter is not an ascii character");
        static if ('a' <= C && C <= 'z')
        {
            enum CaptialC = C - 0x20;
            return CaptialC ~ S[1 .. $]; // Also correct when S.length == 1
        }
        else
        {
            return S;
        }
    }
    else
    {
        return S;
    }
}();
