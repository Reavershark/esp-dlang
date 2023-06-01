module idf.string;

@safe @nogc nothrow:

@trusted
{
    immutable immutable(char)* CStringOf(string S) = (S ~ ubyte(0)).ptr;
}
