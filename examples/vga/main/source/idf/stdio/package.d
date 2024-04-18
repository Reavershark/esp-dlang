module idf.stdio;

@safe:

pragma(printf)
extern(C)
int printf(scope const char* fmt, scope const ...);