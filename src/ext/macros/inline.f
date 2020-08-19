\ inline.f   - x4 macro creation and inlining
\ ------------------------------------------------------------------------

  .( inline.f )

\ ------------------------------------------------------------------------

  <headers

  0 var was-branch          \ true if last token was a branch
  0 var m-start             \ start address of current macro definition
  0 var m-new               \ address macro is being inlined to
  0 var m-exit              \ exit point of macro

\ ------------------------------------------------------------------------

: (is-quote)    ( token --- token f1 )
  dup
  ['] (.")
  ['] (abort")
  either ;

\ ------------------------------------------------------------------------
\ is current token a (.") or a (abort")

: is-quote?     ( a1 token --- a1 token false | a2 true )
  (is-quote) dup 0= ?exit   \ return false if token not a quote
  >r ,                      \ save true for exit and compile the " token
  count -1 /string          \ get string length and address
  2dup s, + r> ;            \ compile string, advance addr, return true

\ ------------------------------------------------------------------------
\ words that have a branch vector compiled after them

\ it is assumed that a branch vector is absolute, not relative
\ - this is a true assumption in x4 -

create branches
  ' (nxt)    ,   ' (do)     ,   ' (?do)    ,   ' doif     ,
  ' doelse   ,   ' (loop)   ,   ' (+loop)  ,   ' dobegin  ,
  ' ?while   ,   ' dorepeat ,   ' doagain  ,   ' ?until   ,

  12 const #branches

\ ------------------------------------------------------------------------
\ is the current xt a branching type word?

: is-branch?    ( xt --- f1 )
  branches #branches pluck  \ search above table for specified token
  qscan nip 0= not
  !> was-branch ;           \ indicate next xt is the branch vector

\ ------------------------------------------------------------------------
\ expand a xt from a macro into its target definition

: ((m:))        ( a1 xt --- a2 )
  is-quote? ?exit           \ handle " token if it is one, exit if it was
  was-branch                \ was the previous token a branch?
  if
    swap wcount w,
    swap
    off> was-branch         \ clear flag
  else
    is-branch?              \ is the current token a branch?
  then
  ,xt ;                     \ compile token, advance address

\ ------------------------------------------------------------------------

: (m:)     ( a1 --- )
  qcount !> m-exit          \ fetch the compiled exit point of macro
  dup !> m-start            \ point to body of macro
  here !> m-new             \ fetch address to inline macro to

  begin
    dup m-exit <>           \ reached end of macro?
  while
    dup xt@ ((m:)) 5 +      \ no - fetch and process next token
  repeat
  drop ;                    \ yes - clean up

\ ------------------------------------------------------------------------
\ start a macro colon definition

  headers>

: m:
  inline>                   \ initialize macro compilation
  create immediate          \ create new word and make it immediate
  >mark                     \ compile dummy macro exit point
  ]                         \ switch into compile mode
  does> (m:) ;              \ patch macros cfa

\ ------------------------------------------------------------------------
\ complete definition of a macro colon definition

: ;m
  >resolve                  \ compile exit point of macro
  [compile] -;              \ switch out of compile mode
  <inline ; immediate

\ there is no exit compiled onto the end of a macro : definition

\ ========================================================================
