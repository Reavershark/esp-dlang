pragma(printf)
extern(C) int printf(scope const char* fmt, scope const ...) nothrow @nogc;

struct A
{
    int val;
}

extern(C) void main()
{
    int* aPtr = new int(20);
    printf("a = %d", *aPtr);
}
