module utils.string;

@safe @nogc nothrow:

@trusted
{
    immutable immutable(char)* CStringOf(string S) = (S ~ '\0').ptr;
}
