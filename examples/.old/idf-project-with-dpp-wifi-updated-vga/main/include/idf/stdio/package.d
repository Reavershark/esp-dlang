module idf.stdio;

public import idf.stdio.stdio_dpp;

// Redefine some functions with added attributes and pragma(print/fscanf) for compile-time format string checking
extern(C) @trusted
{
    pragma(printf)
    int printf(scope const char* fmt, scope const ...);

    int puts(scope const char* s);

    int putchar(scope const char c);
}

void printfln(Args...)(scope const char* fmt, scope const args) @safe
{
    printf(fmt, args);
    printf("\r\n");
}

void print(scope const char* str) @safe
{
    puts(str);
}

void println(scope const char* str) @safe
{
    puts(str);
    puts("\r\n");
}
