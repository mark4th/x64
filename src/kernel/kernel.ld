
ENTRY(origin)

SECTIONS
{
    .text : { *(.text) *(headers) }
    .bss : ALIGN(1)
    {
      *(.bss)
      . = . + 0x100000 - (SIZEOF(.text) + SIZEOF(.data));
    }
}


