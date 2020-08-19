\ case.f        - x64 case compilation and execution
\ ------------------------------------------------------------------------

  .( loading case.f ) [cr]

\ ------------------------------------------------------------------------

  compiler definitions

\ ------------------------------------------------------------------------

  <headers

  0 var [default]           \ default case vector
  0 var #case               \ number of case options

\ ------------------------------------------------------------------------
\ get default for case: statement

  headers>

: default: ( --- )
  ' !> [default] ;           \ compiled in later by ;case

\ ------------------------------------------------------------------------
\ initiate a case statement

: case:        ( --- 0 )
  compile docase            \ compile run time handler for case statement
  off> [default]            \ assume no default vector
  off> #case                \ number of cases is 0 so far
  \ can not use >mark because thats used to compile a 16 bit branch vector
  here 0 ,                  \ case exit point compiled to here
  here 0 ,                  \ default vector filled in by ;case (maybe)
  here 0 ,                  \ number of cases compiled to here
  [compile] [ ; immediate

\ ------------------------------------------------------------------------
\ when i originally developed this case statement compiler i was told that
\ i should not call this word "of" because of the differences between how
\ i implement this and how ANS standard would implement it.  I therefore
\ originally named this "opt".  I have since decided that there is no real
\ conflict because no ans forth is actually compliant with any other ans
\ forth.  Im calling this "of" again.

: of          ( opt --- )
  ,                         \ compile opt
  ' ,                       \ get vector and compile it too
  incr> #case ;             \ count number of cases in statement

\ ------------------------------------------------------------------------
\ i resisted the urge to call this word esac :p (phew!!!)

: ;case         ( a1 a2 a3 --- )
  #case swap !              \ back fill case count
  [default] swap !          \ back fill default vector
  here swap ! ] ;           \ back fill  case exit

\ ------------------------------------------------------------------------

 forth definitions behead

\ ========================================================================
