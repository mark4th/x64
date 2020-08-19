\ fsave.f       - x4 saves out elf executable
\ ------------------------------------------------------------------------

  .( loading fsave.f ) [cr]

\ ------------------------------------------------------------------------

  compiler definitions

\ ------------------------------------------------------------------------
\ elf header structure

  <headers

struct: elf_header
  16 db e_ident             \ $7f $45 $4c $46 etc etc
   1 dw e_type              \ 2 = executable
   1 dw e_machine           \ 3 = X86   20 = ppc
   1 ds e_version           \ 1 = current
   1 dq e_entry             \ entry point of process (origin)
   1 dq e_phoff             \ offset to start of program headers
   1 dq e_shoff             \ offset to start of section headers
   1 ds e_flags             \ zero
   1 dw e_ehsize            \ byte size of elf header
   1 dw e_phentsize         \ byte size of program header
   1 dw e_phnum             \ number of program headers
   1 dw e_shentsize         \ size of section header
   1 dw e_shnum             \ number of section header entreis
   1 dw e_shstrndx          \ index to string sections section header
;struct

\ ------------------------------------------------------------------------
\ e_type

enum: ET_TYPES
  := ET_NONE                \ no file type
  := ET_REL                 \ relocatble file
  := ET_EXEC                \ executable file
  := ET_DYN                 \ shared object
  := ET_CORE                \ ok so why am i including this one again?
;enum

\ ------------------------------------------------------------------------
\ e_machine

enum: EM_TYPES
   3 /= EM_386               \ intel 386? ewww
  20 /= EM_PPC               \ ppc
  21 /= EM_PPC64             \ 64 bit ppc
  40 /= EM_ARM               \ up to v7a
  62 /= EM_AMD64
 183 /= EM_ARM64
;enum

\ ------------------------------------------------------------------------
\ structure of a program header

struct: prg_header
   1 ds p_type
   1 ds p_flags
   1 dq p_offset
   1 dq p_vaddr
   1 dq p_paddr
   1 dq p_filesz
   1 dq p_memsz
   1 dq p_align
;struct

\ ------------------------------------------------------------------------

enum: PT_TYPES
  := PT_NULL
  := PT_LOAD
  := PT_DYNAMIC
  := PT_INTERP
  := PT_NOTE
  := PT_SHLIB
  := PT_PHDR
;enum

\ ------------------------------------------------------------------------

enum: PF_TYPES
  1 /= PF_X
  2 /= PF_W
  4 /= PF_R
;enum

  PF_X PF_R or const PF_RX
  PF_R PF_W or const PF_RW

\ ------------------------------------------------------------------------
\ section header structure

struct: sec_header
  1 ds sh_name              \ offset in $ table to name
  1 ds sh_type              \ 1 = progbits
  1 dq sh_flags             \ 6 = AX
  1 dq sh_addr              \ where this section lives
  1 dq sh_offset            \ file offset to start of section
  1 dq sh_size              \ how big is the section (deja vu)
  1 ds sh_link
  1 ds sh_info
  1 dq sh_addralign
  1 dq sh_entsize
;struct

\ ------------------------------------------------------------------------

enum: SH_TYPES
  := SHT_NULL
  := SHT_PROGBITS
  := SHT_SYMTAB
  := SHT_STRTAB
  := SHT_RELA
  := SHT_HASH
  := SHT_DYNAMIC
  := SHT_NOTE
  := SHT_NOBITS
  := SHT_REL
  := SHT_SHLIB
  := SHT_DYNSYM
;enum

\ ------------------------------------------------------------------------

enum: SH_FLAGS
  1 /= SHF_WRITE
  2 /= SHF_ALLOC
  4 /= SHF_EXEC
;enum

  SHF_ALLOC SHF_EXEC  or const SHF_AX
  SHF_ALLOC SHF_WRITE or const SHF_WA

\ ------------------------------------------------------------------------
\ string section

create $table
  0 c,                      \ 0 index is empty string.
  ,' .text' 0 c,            \ 1
  ,' .bss' 0 c,             \ 7
  ,' .shstrtab' 0 c,        \ 12

  here $table - const st_len

\ ------------------------------------------------------------------------
\ decompiler needs this too

  origin $7fff not and const ELF0

\ ------------------------------------------------------------------------
\ used to calculate bss size

  $100000 const 1MEG        \ this minus .text size = .bss size

\ ------------------------------------------------------------------------

  1 const ELFCLASS32        \ 32 bit class
  2 const ELFCLASS64        \ todo

  1 const ELFDATA2LSB
  2 const ELFDATA2MSB

\ ------------------------------------------------------------------------
\ constants for things that change between ports.

    \ ppc Linux:    enc = 1   abi = 2
    \ x86 Linux:    enc = 1   abi = 1
    \ x86 FreeBSD:  enc = 1   abi = 1

  ELFCLASS64  const CLS     \ 32 bit
  ELFDATA2LSB const ENC     \ data encoding (endianness) (big endian)

  1 const VER               \ current version
  3 const ABI               \ ABI (SysV)    (not in elf std?)

\ ------------------------------------------------------------------------
\ elf identity

create identity
  $7f c, $45 c, $4c c, $46 c, CLS c, ENC c, VER c, ABI c,
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c, $00 c, $00 c,

\ ------------------------------------------------------------------------

  0 var ss-addr
  0 var sh-addr

\ ------------------------------------------------------------------------
\ initilize elf headers at start of process address space

: ehdr!         ( --- )
  identity ELF0 16 cmove    \ copy elf identity into elf header
  ELF0 >r

  ET_EXEC    r@ e_type    w!
  EM_AMD64   r@ e_machine w!
  1          r@ e_version s!
  origin     r@ e_entry   !
  elf_header r@ e_phoff   !

  hhere                     \ address of start of string section
  $1000 + -$1000 and
  dup !> ss-addr st_len +   \ remember str section address
  dup !> sh-addr            \ remember section headers addres

  ELF0 -     r@ e_shoff     !

  0          r@ e_flags     s!
  elf_header r@ e_ehsize    w!
  prg_header r@ e_phentsize w!
  2          r@ e_phnum     w!
  sec_header r@ e_shentsize w!
  4          r@ e_shnum     w!
  3          r> e_shstrndx  w! ;

\ ------------------------------------------------------------------------
\ initialize program headers

: phdr!         ( --- )
  ELF0 elf_header +         \ get address of program headers
  dup prg_header 2* erase   \ start fresh

  >r                        \ .text

  PT_LOAD          r@ p_type    s!
  0                r@ p_offset   !
  PF_RX            r@ p_flags   s!
  ELF0             r@ p_vaddr    !
  ELF0             r@ p_paddr    !
  ss-addr ELF0 -   r@ p_filesz   !
  ss-addr ELF0 -   r@ p_memsz    !
  $1000            r@ p_align    !

  r> prg_header + >r     \ .bss

  PT_LOAD          r@ p_type   s!
  PF_RW            r@ p_flags  s!
  ss-addr ELF0 -   r@ p_offset  !
  ss-addr          r@ p_vaddr   !
  ss-addr          r@ p_paddr   !
  0                r@ p_filesz  !
  1MEG
  ss-addr ELF0 -
  -                r@ p_memsz !
  $1000            r> p_align ! ;

\ ------------------------------------------------------------------------
\ write string section

: $sec!         ( --- )
  $table ss-addr st_len cmove ;

\ ------------------------------------------------------------------------
\ write all section headers

: shdr!        ( --- )
  sh-addr                   \ get address for section headers
  dup sec_header erase      \ first section header is always null
  sec_header + >r           \ point to second secton header

  1               r@ sh_name       s!
  SHT_PROGBITS    r@ sh_type       s!
  SHF_AX          r@ sh_flags      !
  origin          r@ sh_addr       !
  origin ELF0 -   r@ sh_offset     !
  hhere origin -  r@ sh_size       !
  0               r@ sh_link       s!
  0               r@ sh_info       s!
  16              r@ sh_addralign  !
  0               r@ sh_entsize    !

  r> sec_header + >r

  7                r@ sh_name        s!
  SHT_NOBITS       r@ sh_type        s!
  SHF_WA           r@ sh_flags       !
  ss-addr          r@ sh_addr        !
  ss-addr ELF0 -   r@ sh_offset      !
  1MEG
  ss-addr ELF0 -
  -                r@ sh_size !
  0                r@ sh_link        s!
  0                r@ sh_info        s!
  1                r@ sh_addralign   !
  0                r@ sh_entsize     !

  r> sec_header + >r

  12              r@ sh_name        s!
  SHT_STRTAB      r@ sh_type        s!
  0               r@ sh_flags       !
  0               r@ sh_addr        !
  ss-addr ELF0 -  r@ sh_offset      !
  st_len          r@ sh_size        !
  0               r@ sh_link        s!
  0               r@ sh_info        s!
  1               r@ sh_addralign   !
  0               r> sh_entsize     ! ;

\ ------------------------------------------------------------------------

  headers>

: file-open     ( --- fd | -1 )
  \777                      \ rwxrwxrwx
  \1101                     \ O_TRUNC O_CREAT O_WRONLY

  bl word                   \ parse filename from input
  hhere count s>z           \ convert name to ascii z
  <open> ;                  \ create new file

  <headers

\ ------------------------------------------------------------------------
\ save elf file image in memory to file

: ((fsave))
  file-open                 \ parse file name, open file
  dup -1 <>                 \ created?
  if
    >r                      \ save fd to return stack
    off> >in off> #tib      \ so targets tib is empty on entry
    sh-addr                 \ calculate length of file...
    sec_header 4* +         \ i.e. address of end of section headers
    ELF0 -                  \ minus address of start of process
    ELF0 r@ <write>         \ start address of file data
    <close>                 \ write/close file
  else
    ." fsave failed!" cr
  then
  bye ;

\ ------------------------------------------------------------------------
\ save out extended kernel - headers may or may not have been stripped

: (fsave)
  ['] query is refill       \ fsaving or turnkeying from an fload leaves
  off> floads               \ these in a wrong state for the target

  ehdr!                     \ write elf headers into memory
  phdr!                     \ write program headers into memory
  $sec!                     \ write string table into memory
  shdr!                     \ write section headers into memory

  ((fsave)) ;               \ save out memory :)

\ ------------------------------------------------------------------------
\ pack all headers to 'here' and save out executable

  headers>

: fsave
  pack (fsave) ;            \ pack headers onto end of list space

\ ------------------------------------------------------------------------
\ same as fsave but does not pack headers onto end of list space

: turnkey
  here $3ff + -400 and hp ! \ obliterate all of head space
  on> turnkeyd              \ target doesn't try to relocate non existent
  (fsave) ;                 \   headers when it loads in !!!

\ ========================================================================
