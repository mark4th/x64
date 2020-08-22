
ENTRY(origin)

SECTIONS
{
    . = 0x401000;
    .text : { *(.text) *(headers) }

    .bss : ALIGN(1)
    {
      *(.bss)
      . = . + 0x100000 - (SIZEOF(.text));
    }
}


