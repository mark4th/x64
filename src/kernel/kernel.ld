
ENTRY(origin)

SECTIONS
{
    PROVIDE (__executable_start = SEGMENT_START("text-segment", 0x40000));
    . = SEGMENT_START("text-segment", 0x4000000) + SIZEOF_HEADERS;

    .text : { *(.text) *(headers) }

    .bss : ALIGN(1)
    {
      *(.bss)
      . = . + 0x100000 - (SIZEOF(.text));
    }
}


