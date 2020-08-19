\ dealloc.f     - x4 memory deallocation
\ ------------------------------------------------------------------------

  .( dealloc.f )

\ ------------------------------------------------------------------------

  <headers

\ -----------------------------------------------------------------------
\ merge contiguous upper memory block into lower memory block

\ merging of blocks always retains the lower block and
\ discards the upper block

: (merge)     ( mem-blk1 mem-blk2 --- mem-blk1 )
  dup blk.size@             \ get size of upper contiguous region
  swap discard-blk          \ discard mem-blk descriptor for upper block
  over blk.size@ +          \ add size of upper block to lower block
  over blk.size! ;

\ -----------------------------------------------------------------------

: (merge>)    ( mem-blk meta --- mem-blk` )
  meta +                    \ the following @meta will do meta-
  @meta <list
  (merge) ;

\ -----------------------------------------------------------------------
\ merge block to be deallocated with congiguous free region above it

: merge>      ( mem-blk --- mem-blk )
  dup blk.addr@             \ get address of region above one to free
  over blk.size@ +

  dup meta.magic@ f-magic = \ is it also an un-allocated region?
  ?:
    (merge>)
    drop ;

\ -----------------------------------------------------------------------

: (<merge)    ( mem-blk meta --- mem-blk' )
  @meta <list
  swap (merge) ;

\ -----------------------------------------------------------------------
\ merge block to be deallocated with contiguous free region below it

: <merge      ( mem-blk --- mem-blk )
  dup blk.addr@             \ get address of region below one to be freed
  dup meta -                \ examine its upper guard block
  meta.magic@ f-magic =
  ?:
    (<merge)
    drop ;

\ -----------------------------------------------------------------------
\ deallocate specified mem-blk

: (free)        ( mem-blk --- f1 )
  dup blk.heap@ >r          \ retain mem-blks parent heap address
  <list <merge merge>       \ unlink from allocated map, merge adjacent

  dup blk.size@             \ fetch merged size of block being freed
  r@ heap.psize @ =         \ fetch size of heaps pool
  if                        \ if they are the same
    drop r> destry-heap     \ return entire heap pool to BIOS (linux)
  else                      \ otherwise
    r> heap.mapf@           \ link deallocated block to heaps free
    swap add-free           \ blocks mem-map
  then

  true ;                    \ return success

\ ------------------------------------------------------------------------

  headers>

: free          ( addr --- f1 )
  @meta (free) ;            \ convert addr to mem-blk and deallocate

\ ========================================================================
