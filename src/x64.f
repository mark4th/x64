\ x64 extensions load file
\ ------------------------------------------------------------------------

  cr cr .( extending x64 system ) cr cr

\ ------------------------------------------------------------------------
\ this is used to track how much source code is compiled during the extend

  ' ktotal >body off            \ off> has not been defined yet

\ ------------------------------------------------------------------------
\ make an alias for forths cr so we dont call the uninitlized termainal cr

  ' cr alias [cr]

\ ------------------------------------------------------------------------
\ *     required files
\ +     optional files
\ -     dont include in turnkey apps
\ ------------------------------------------------------------------------


\ ------------------------------------------------------------------------
\ most of this is required

  fload src/ext/loops.f         \ * loop and branch compilation words
  fload src/ext/variable.f      \ * variable creating words etc
  fload src/ext/number.f        \ * pictured number output

  \ ----------------------------------------------------------------------
  \ displays offending line number during an fload

  \ any errors in any of the above floads wont have
  \ their line number echo'd.   everything below will

  : (.line#)
    floads 0= ?exit
    ." Line Number " line# . ;
   ' (.line#) is .line#

  \ ----------------------------------------------------------------------

  fload src/ext/header.f        \ * headerless word creation
  fload src/ext/vocabs.f        \ *
  fload src/ext/struct.f        \ * structure definition words
  fload src/ext/stacks.f        \ + software stacks
  fload src/ext/fsave.f         \ * turnkey and fsave
  fload src/ext/tty.f           \ * terminal initializtion
  fload src/ext/args.f          \ * command line args primatives
  fload src/ext/env.f           \ * environment searching
  fload src/ext/case.f          \ * case statements

\ ------------------------------------------------------------------------
\ memory manager below uses these

  fload src/ext/list.f          \ + linked list words

\ ------------------------------------------------------------------------
\ macro colon definitions (basiclaly these are : macros )

  .( loading macro inliners: )

  fload src/ext/macros/macros.f \ -
  fload src/ext/macros/inline.f \ -
  [cr]

  behead forth definitions

\ ------------------------------------------------------------------------
\ memory manager

\ while this is marked as optonal there are alot of extensions
\ below that depend on this

  .( loading mem-manager: )

  fload src/ext/memman/memory.f     \ +
  fload src/ext/memman/util.f       \ +
  fload src/ext/memman/heap.f       \ +
  fload src/ext/memman/alloc.f      \ +
  fload src/ext/memman/dealloc.f    \ +
  fload src/ext/memman/info.f       \ +
  [cr]

\ ------------------------------------------------------------------------

  fload src/ext/file.f               \ + file i/o

  .( loading date/time: )

  fload src/ext/datetime/timer.f     \ + delays and elapsed time measurement
  fload src/ext/datetime/localtime.f \ + displaying time and timing things
  fload src/ext/datetime/date.f      \ +
  [cr]

  behead

\ ------------------------------------------------------------------------

 fload src/ext/rnd.f               \ + random number generator
 fload src/ext/utils.f             \ + usefull stuff to have around
 fload src/ext/message.f           \ +

\ ------------------------------------------------------------------------
\ terminfo handling etc

  .( loading terminfo: )

  fload src/ext/terminal/term.f     \ + curses without the cussing
  fload src/ext/terminal/tformat.f  \ + terminfo format strings
  fload src/ext/terminal/terminfo.f \ + terminfo parsing etc
  fload src/ext/terminal/color.f    \ + colour output
  fload src/ext/terminal/keys.f     \ + common keyboard handler code

\ todo: put back in when signals fixed
\  fload src/ext/terminal/twinch.f   \ + window change signal handling
  [cr]

\ ------------------------------------------------------------------------
\ the above modules have not been beheaded yet

  .( loading text-ui:  )

  fload src/ext/tui/tui.f       \ + text user interface (aka curses)
  fload src/ext/tui/scrdsp.f    \ + screen display update
  fload src/ext/tui/screen.f    \ + screen creation
  fload src/ext/tui/windsp.f    \ + window display update
  fload src/ext/tui/window.f    \ + window creation
  fload src/ext/tui/border.f    \ + draw window borders
  [cr]

  \ .( loading menus:    )

  \ fload src/ext/tui/menu.f      \ + pulldown menus
  \ fload src/ext/tui/menudsp.f   \ + menu display
  \ fload src/ext/tui/menuctl.f   \ + menu control
  \ [cr]

  behead forth definitions

\ ------------------------------------------------------------------------
\ sockets related (work in progress but useable - no dns yet :)

  \ fload src/ext/sockets.f        \ + socket connect/read/write
\ *** fload src/ext/resolver.f   \ + dns queries

\ ------------------------------------------------------------------------
\ some usefull utils

  fload src/ext/words.f         \ - vocabulary listings
  fload src/ext/forget.f        \ - forget, empty etc
  fload src/ext/history.f       \ - command line history
  fload src/ext/hello.f         \ - nice signon message
  fload src/ext/status.f        \ - status line display
  fload src/ext/tail.f          \ - default args handler
  fload src/ext/utf8.f            \ + utf8 emit

\ ------------------------------------------------------------------------

  fload src/ext/dents.f           \ + directory reading

\ ------------------------------------------------------------------------
\ custom initialization

\  fload src/ext/init.f          \ + interpret ~/.x4.rcf

\ ------------------------------------------------------------------------
\ save out extended forth - does not return - implied bye

  cr .( depth = ) depth .
  cr .( compiled ) ktotal . .( bytes ) cr
  cr .( writing extended compiler )

  forth definitions
  fsave x64

\ ========================================================================
