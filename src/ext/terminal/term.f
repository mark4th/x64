\ term.f   - open terminfo file for reading
\ ------------------------------------------------------------------------

  .( term.f )

\ ------------------------------------------------------------------------

\ this file loads the correct terminfo file for the terminal being used
\ and sets pointers to the various sections within that file for use by
\ the definitions within terminfo.f

\ ------------------------------------------------------------------------

  vocabulary terminal terminal definitions

\ ------------------------------------------------------------------------

  0 var t-size              \ size of terminfo memory mapping
  0 var terminfo            \ address of terminfo memory mapping

\ ------------------------------------------------------------------------
\ escape sequences compiled to this buffer

  0 var $buffer             \ output string compile buffer
  0 var #$buffer            \ number of characters compiled to $buffer

  <headers

\ ------------------------------------------------------------------------

  create ti-path 64 allot
  create TERM    64 allot
  0 var t-letter           \ first letter of $TERM
  create env-term  ," TERM"

  create p1 ," /usr/share/terminfo/./"
  create p3 ," /lib/terminfo/./"
  create p2 ," /etc/terminfo/./"
  create p4 ," ~/terminfo/./"

create paths
  p1 , p2 , p3 , p4 ,

\ ------------------------------------------------------------------------

: map-info   ( fd --- )
  dup 1 dup fmmap
  !> t-size !> terminfo
  fclose ;

\ ------------------------------------------------------------------------

: (open-terminfo)     ( --- fd t | f )
  4 0
  do
    ti-path 64 erase
    paths i []@ count -1 /string
    ti-path swap cmove

    t-letter ti-path count + 2- c!

    TERM count ti-path $+

    $22 0 ti-path fopen
    dup -1 <>
    if
      map-info
      true undo exit
    then
  loop
  false ;

\ ------------------------------------------------------------------------

: open-terminfo
  env-term getenv           \ ( a1 n1 f1 --- )
  if
    over c@ !> t-letter
    dup TERM c!
    TERM 1+ swap cmove
    (open-terminfo)
  else
    ." Unknown $TERM: " TERM count type cr
    bye
  then ;

\ ------------------------------------------------------------------------
\ pointers to each section within terminfo file

\ these are realy constants but we dont kmow their values yet

  0 var t-names             \ names section
  0 var t-bool              \ bool section
  0 var t-numbers           \ numbers section
  0 var t-strings           \ string section (offsets within following)
  0 var t-table             \ string table
  0 var wide                \ true if using new format terminfo

\ -----------------------------------------------------------------------
\ various buffers used when parsing escape sequence format strings

  0 var f$                  \ format string parse address
  0 var params              \ format string parameters
  0 var a-z                 \ format string variables
  0 var A-Z                 \ format string variables

\ ------------------------------------------------------------------------
\ an evil forward reference

  defer >format             \ store one sequence in output buffer

\ ------------------------------------------------------------------------

  headers>

  defer .$buffer            \ write whole output buffer (to display?)

  <headers

\ ------------------------------------------------------------------------
\ allocate a buffer of n1 bytes in size

: ?alloc        ( n1 --- a1 )
  allocate ?exit
  ." Cannot Allocate Terminal Buffers"
  bye ;

\ ------------------------------------------------------------------------
\ alloate terminal output buffer

: alloc-buffers
  32768 ?alloc !> $buffer   \ sequence output buffer
  [ 9 cells ]#              \ 9 parameters max
  ?alloc !> params          \ format string parameter buffer
  [ 'z' 'a' - cells ]#      \ calculate number of cells for variables
  dup ?alloc !> a-z         \ format string variable buffers
      ?alloc !> A-Z ;

\ ------------------------------------------------------------------------
\ terminfo file header format

struct: header
  1 dw tmagic               \ magic number
  1 dw tnames               \ length of terminal names section
  1 dw tbool                \ length of boolean section
  1 dw tnumbers             \ # of 16/32 bit items in numbers section
  1 dw tstrings             \ number of strings in string section
  1 dw stsize               \ size in bytes of string table
;struct

\ ------------------------------------------------------------------------
\ initialize pointers to each section within terminfo file

: ?wide wide ?: 4* 2* ;
: talign dup 1 and + ;
: +dup + dup ;

\ ------------------------------------------------------------------------

: init-pointers
  terminfo dup>r header           +dup !> t-names
  r@ tnames   w@                  +dup !> t-bool
  r@ tbool    w@ + talign          dup !> t-numbers
  r@ tnumbers w@ ?wide            +dup !> t-strings
  r> tstrings w@ 2* + talign           !> t-table ;

\ ------------------------------------------------------------------------

: valid   ( magic --- )
  $21e = !> wide ;          \ set wide = true for extended terminfo files

\ ------------------------------------------------------------------------

: invalid
  ." Terminfo: Bad Magic!"
  bye ;

\ ------------------------------------------------------------------------
\ quits forth if terminfo file is corrupted

: valid?
  terminfo w@ dup
  $11a $21e either
  ?: valid invalid ;

\ ------------------------------------------------------------------------
\ read terminfo file and calculate addresses for each section therein

: get-info
  defers default            \ add to default init chain

  open-terminfo valid?      \ test sanity of terminfo file

  alloc-buffers             \ allocate buffers
  init-pointers ;           \ initialize pointers to each section

\ ------------------------------------------------------------------------
\ store n1 parameters in paramter table

: >params       ( ... n1 --- )
  params 36 erase         \ zero all parameters
  ?dup 0= ?exit
  ?dup 9 >
  if
    rep drop exit
  then
  for
    params r@ []!
  nxt ;

\ ------------------------------------------------------------------------
\ translate alt charset character prior to emit (not done automatically)

  headers>

\ this is not actually used anywhere, not sure there are any
\ terminals where the char you are translating from is not
\ identical to the char you are translating from...

: >acsc      ( c1 --- c2 )
  t-strings 292 + w@
  t-table + 60 pluck scan
  if
    1+ c@ nip
  else
    drop
  then ;

\ ========================================================================
