\ util.f    - memory mapping utility functions
\ ------------------------------------------------------------------------

  .( util.f )

\ ------------------------------------------------------------------------
\ getters and setters. only defined the most commonly used ones

\ NOTE:  we cannot make these macro colon definitions because m: forward
\ references this memory manager

: heap.mapa@ ( heap --- mem-map ) heap.mapa @ ;
: heap.mapf@ ( heap --- mem-map ) heap.mapf @ ;
: heap.mapa! ( mem-map heap --- ) heap.mapa ! ;
: heap.mapf! ( mem-map heap --- ) heap.mapf ! ;

: blk.heap@ ( mem-blk --- heap ) blk.heap @ ;
: blk.addr@ ( mem-blk --- addr ) blk.addr @ ;
: blk.size@ ( mem-blk --- size ) blk.size @ ;

: blk.heap! ( heap mem-blk --- ) blk.heap ! ;
: blk.addr! ( addr mem-blk --- ) blk.addr ! ;
: blk.size! ( size mem-blk --- ) blk.size ! ;

: meta.blk@   ( meta --- mem-blk ) meta.mem-blk @ ;
: meta.magic@ ( meta --- magic )   meta.magic @ ;
: meta.chk@   ( meta --- chk )     meta.chk @ ;
: meta.blk!   ( mem-blk meta --- ) meta.mem-blk ! ;
: meta.magic! ( magic meta --- )   meta.magic ! ;
: meta.chk!   ( chk meta --- )     meta.chk ! ;

\ ------------------------------------------------------------------------
\ calculate mem-map index for a given block size

\ note: modification of map-size will require the following table be
\ recalculated.  could algorithmically create this table at compile time

create masks
  $ff000000 s, $ff800000 s, $ffc00000 s, $fff00000 s,
  $fff80000 s, $fffc0000 s, $ffff0000 s, $ffff8000 s,
  $ffffc000 s, $fffff000 s, $fffff800 s, $fffffc00 s,
  $ffffff00 s, $ffffff80 s, $ffffffc0 s, $ffffffff s,

: ?index        ( size --- ix )
  map-size 0                \ 16 different size ranges
  do
    dup masks i             \ and size with next range mask
    [s]@ and
    if                      \ did mask hit any bits?
      drop i leave          \ if so return index
    then
  loop ;

\ ------------------------------------------------------------------------
\ convert map index to an address within a map

: >map-n        ( mem-map ix --- a1 )
  llist * + ;               \ advance to bucket[ix]

\ ------------------------------------------------------------------------
\ get address of mem-map bucket for given mem-blk descriptor

: ?map          ( mem-map mem-blk --- list )
  blk.size@ ?index          \ get mem-map index for this blk
  >map-n ;                  \ return pointer to linked list bucket

\ ------------------------------------------------------------------------
\ first 16 bytes of all allocations are meta data used by mem manager

: !meta         ( magic mem-blk --- )
  dup blk.addr@ dup>r       \ get address of this blocks buffer
  meta erase                \ erase meta data
  r@ 2dup !                 \ store mem-blk address into meta data
  rot over cell+ !          \ write magic mark to meta data
  swap dup blk.size@ >r     \ store inverse mem-blk as checksum
  not swap [ 3 cells ]# + ! \ copy lower guard block to top of memory
  2r> tuck + meta -         \ for this allocation
  meta cmove ;

\ ------------------------------------------------------------------------
\ attach a mem-blk descriptor to a given mem-map

: add-mem       ( mem-map mem-blk magic --- )
  over !meta                \ store meta data in regions guard blocks
  dup 0links                \ nullify structures linkages
  tuck ?map                 \ get correct bucket
  >head ;                   \ add descriptor to head of chain

\ todo:
\
\ we could make this a better best fit algorithm by linking each mem-blk
\ descriptor in some sorted order here.  this would allow us to see
\ immediately if a given chain contains a block large enough for a given
\ allocation or if we need to utilize a descriptor from the next
\ largest chain.  This would speed up allocations greatly.

\ ------------------------------------------------------------------------

: add-free      ( mem-map mem-blk --- )  f-magic add-mem ;
: add-aloc      ( mep-map mem-blk --- )  a-magic add-mem ;

\ ------------------------------------------------------------------------
\ recycle a previously assigned but now unused mem-blk descriptor

: @cached       ( heap --- mem-blk )
  heap.cached <head ;       \ not to be confused with hcache

\ ------------------------------------------------------------------------
\ fetch contents of then increment contents of a given address

: @\++           ( a1 --- n1 )
  dup @                     \ duplicate address, fetch its contents
  swap incr ;               \ get address back, increment its contents

\ ------------------------------------------------------------------------
\ assign new mem-blk from array of unassigned descriptors

: (describe)   ( heap --- mem-blk )
  dup>r heap.blocks @ r>    \ point to array of mem-blks
  heap.bcount @\++          \ index to next unassigned descriptor
  mem-blk * + ;             \ return address of this descriptor

\ ------------------------------------------------------------------------
\ create descriptor for block of memory

: describe      ( a1 n1 heap --- mem-blk )
  dup>r dup heap.cached head@  \ any cached/unused mem-blk structures?
  ?: @cached (describe)        \ recycle or make a new one

  \ ( a1 n1 mem-blk --- )

  dup mem-blk erase         \ erase descriptor
  tuck blk.size!            \ set size and address of memory block
  tuck blk.addr!
  r> over blk.heap! ;       \ remember heap this descriptor goes with

\ ------------------------------------------------------------------------
\ clone a block descriptor

: clone-blk  ( mem-blk --- mem-blk` mem-blk )
  dup>r blk.addr@           \ get address of mem-blk
  r@ blk.size@              \ get size of mem-blk
  r@ blk.heap@              \ get heap of mem-blk
  describe r> ;             \ create second descriptor for block

\ ------------------------------------------------------------------------
\ split off a 'size' chunk of memory from a given mem-blk

: split-blk     ( mem-blk1 size --- mem-blk2 mem-blk1` )
  >r clone-blk              \ create clone of mem-blk1
  r@ over blk.size!         \ new block = addr to addr + size
  swap

  r@ over blk.addr +!          \ advance old block addr beyond new block
  r> negate over blk.size +! ; \ adjust size for part we chipped off

\ before
\    +----------------------------+
\    |<---------mem-blk1--------->|
\    +----------------------------+

\ after
\    +------------+---------------+
\    |<-mem-blk2->|<---mem-blk1-->|
\    +------------+---------------+
\       ^---.
\  we wish to allocate this much but the buffer was bigger than we needed
\  so we fragment the buffer and take only the bit we need.

\ ------------------------------------------------------------------------
\ align size to exact multiple of 16 bytes

: align16       ( size --- size` )
  15 + -16 and ;            \ granularity of allocations is 16 bytes

\ ------------------------------------------------------------------------
\ verify meta data and if it is not corrupted return saved mem-blk

\ the address passed in to this word is the address of the user area of
\ the allocated buffer.  the meta data is 16 bytes below this.
\
\ user code might erroneously overwrite the meta data at the start of an
\ allocated buffer.  if this happens we simply return the address of the
\ start of the buffer proper (the meta data address) and search all the
\ heaps for a buffer starting at this address and get its mem-blk that
\ way.

: @meta         ( addr --- mem-blk t )
  meta - >r                 \ point at meta data
  0                         \ prime checksum
  r@ meta bounds            \ for each byte of meta data
  do
    i c@ xor                \ fetch byte and xor with checksum
  loop

  abort" Memory Guard Block Corruption"

  r> meta.blk@ ;            \ meta data = buffers mem-blk descriptor

\ -----------------------------------------------------------------------
\ discard mem-blk - attach to list of cached / unused blocks

: discard-blk       ( mem-blk --- )
  dup 0links                \ no longer part of any linked lists
  dup blk.heap @            \ which heap owns this block
  heap.cached >head ;       \ link block to heaps cached mem-blk list

\ ========================================================================
