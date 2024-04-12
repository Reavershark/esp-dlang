module idf.soc.i2s_reg.utils_for_c;

uint BIT(int i)
in (0 <= i && i < typeof(return).sizeof)
{
    return 1 << i;
}