module idf.stdio;

public import idf.stdio.includes_dpp;

@safe @nogc nothrow:

// Redefine some functions with added attributes and pragma(print/fscanf) for compile-time format string checking
extern(C) @trusted
{
    pragma(printf)
    int printf(scope const char* fmt, scope const ...);

    int puts(scope const char* s);

    int putchar(scope const char c);
}
