module utils.string;

@safe @nogc nothrow:

@trusted
{
    enum string StringzOf(string S) = (S ~ '\0');
    enum immutable(char)* StringzPtrOf(string S) = (S ~ '\0').ptr;
}
