; compile.s      - x4 creating and compilation words
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------

  _var_ 'state', state, 0   ; 0 = interpret, -1 = compile
  _var_ 'last', last, 0     ; nfa of most recently defined word

; ------------------------------------------------------------------------
; put forth in interpret mode

  _immediate_

code '[', l_bracket
  mov qword [state_b], 0
  next

; ------------------------------------------------------------------------
; put forth in compile mode

code ']', r_bracket
  mov qword [state_b], -1
  next

;-------------------------------------------------------------------------
; compile a call from address a2 to address a1

;    : call!       ( a1 a2 --- )
;        $e8 over c! dup>r
;        5 + - r> 1+ ! ;


colon "call!", call_store
  literal 0xe8              ; call opcode
  xt over
  xt c_store
  xt dup_to_r               ; save address of opcode were compiling
  literal 5                 ; calculate delta to call target
  xt plus
  xt minus
  xt r_to                   ; compile delta after opcode
  xt one_plus
  xt s_store
  exit

;-------------------------------------------------------------------------
; compile a call instruction from here to a1

;    : ,xt          ( a1 --- )
;        here 5 allot call! ;

colon ',xt', comma_xt
  xt here
  literal 5                 ; call opcode is 5 bytes
  xt allot
  xt call_store
  exit

; ------------------------------------------------------------------------
; convert a call opcode at address a1 into absolute address of its target

; no check is done that a1 points to an actual call opcode

;     ( a1 --- a2 )

code "xt@", xt_fetch
  mov eax, dword [rbx + 1]
  lea ebx, [rbx + rax + 5]
  next

; ------------------------------------------------------------------------

;     ( --- a1 )

code "(compile)", p_compile
  apush rbx
  mov rbx, qword [RP]       ; get callers return address
  add qword [RP], byte 5    ; advance it past parameter
  jmp xt_fetch              ; convert call opcode to abs address

; ------------------------------------------------------------------------
; compile inline item (from current executing def) into new definition

;    : compile    ( --- )
;        (compile) ,xt ;

colon 'compile', compile
  xt p_compile              ; fetch item to compile from return address
  xt comma_xt               ; compile it into word being created
  exit

; ------------------------------------------------------------------------
; compile an immediate word

;    : [compile]
;        ' ,xt ; immediate

  _immediate_

colon '[compile]', b_compile
  xt tick                   ; parse input for word name and 'find' it
  xt comma_xt               ; compile it in
  exit

; ------------------------------------------------------------------------
; compile literal into : definition

;    : literal    ( n1 --- )
;        32 >> 0=
;        if
;           $bb c, s,
;        else
;           $48 c, $bb c, $48 c,  ,
;        then ; immediate

  _immediate_

;   ( n1 --- )

colon 'literal', literal_
  xt compile
  xt a_push

  mov rax, rbx              ; assemble 0xbb NN NN NN NN
  shr rax, byte 32
  jne .L1
  literal 0xbb
  xt c_comma
  xt s_comma
  exit
.L1:
  literal 0xbb48            ; assemble 0x48 0xbb NN NN NN NN NN NN NN NN
  xt w_comma
  xt comma
  exit

; -----------------------------------------------------------------------
; shorthand for '] literal'

;    : ]#
;         ] literal ; immediate

colon ']#', r_b_sharp
  xt r_bracket
  xt literal_
  exit

; -----------------------------------------------------------------------
; compile word as literal

;    : [']
;        ' literal ; immediate

  _immediate_

colon "[']", b_tick
  xt tick
  xt literal_
  exit

; ------------------------------------------------------------------------
; compile (abort") and the abort message string -- "

;    : abort"
;        compile (abort")
;        ," ; immediate

  _immediate_

colon 'abort"', abort_q
  xt compile
  xt p_abort_q
  xt comma_q
  exit

; ------------------------------------------------------------------------
; compile a string to be displayed at run time

;    : ."
;        compile (.")
;        ," ; immediate

  _immediate_

colon '."', dot_quote
  xt compile
  xt p_dot_q
  xt comma_q
  exit

; ------------------------------------------------------------------------
; patch cfa of last word (non coded defs only) to use specified word

;    : ;uses
;        (compile)
;        last name> call! ;

colon ';uses', s_uses
  xt p_compile
.L1:                        ; ( a1 --- )
  xt last
  xt name_to                ; ( a1 a2 --- )
  xt call_store             ; at cfa if latest (a2) compile call to a1
  exit

; ------------------------------------------------------------------------
; patch last definition to use asm code directly following ;code

;    : ;code
;        r>
;        last name> call! ;

colon ';code', s_code
  xt r_to
  xt branch
  bv s_uses.L1

; ------------------------------------------------------------------------
; define run time action of a word being compiled

;    : does>
;        compile ;code ; immediate

  _immediate_

colon 'does>', does
  xt compile                ; compile ;code at the does> location
  xt s_code                 ; does not need a do_does
  xt compile
  xt dodoes
  exit

; ------------------------------------------------------------------------
; create new dictionary entry

colon 'create', create
  xt head_comma             ; create header for new word
  xt compile                ; compile call to dovariable in new words cfa
  xt do_variable
  xt reveal                 ; link header into current
  exit

; ------------------------------------------------------------------------
; make the most recent forth definition an immediate word

colon 'immediate', immediate
  literal IMM               ; immediate flag value
  xt last                   ; get addrress of nfa of last word
  xt c_set                  ; make word immediate
  exit

; ------------------------------------------------------------------------
; create a second header on an already existing word whose cfa is at a1

;     ( cfa --- )

colon 'alias', alias
  xt head_comma             ; create new header
  literal -8                ; deallocate cfa pointer that points to here
  xt dup
  xt h_allot                ; deallocate nfa pointer at cfa -8
  xt allot

  xt dup                    ; point header at cfa of word to alias
  xt h_comma

  xt to_name                ; does word being aliased have an nfa?
  xt q_dup
  xt do_if
  bv .L2
  xt c_fetch                ; get name field count byte and lex bits
  literal IMM               ; is it immediate
  xt and_
  xt do_if
  bv .L1
  xt immediate              ; make alias immediate too
.L1:
  xt do_then
.L2:
  xt do_then
  literal ALIAS             ; mark this as an alias
  xt last                   ; see header relocation code
  xt c_set
  xt reveal                 ; link alias into vocabulary
  exit

; ------------------------------------------------------------------------
; create a defered word - (a re-vectorable word, not a fwd reference)

colon 'defer', defer
  xt create                 ; create new dictionary entry
  xt s_uses                 ; patch new word to use dodefer not dovariable
  xt do_defer
  literal crash             ; compile default vector into defered word
  xt comma
  exit

; ------------------------------------------------------------------------
; add current definition onto end of defered chain (or beginning!!)

  _immediate_

colon 'defers', defers
  xt last                   ; get cfa of word being defined
  xt name_to
  xt tick                   ; get body field address of defered word
  xt to_body
  xt dup                    ; compile its contents into word being defined
  xt fetch
  xt comma_xt
  xt store                  ; point defered word at new word
  exit

; ------------------------------------------------------------------------
; begin compiling a definition

colon ':', colon_
  xt head_comma
  xt compile
  xt nest
  xt r_bracket              ; set state on (were compiling now)
  exit

; ------------------------------------------------------------------------

  _immediate_

colon '-;', d_semi
  xt l_bracket
  xt reveal
  exit

; ------------------------------------------------------------------------
; complete definition of a colon definition

  _immediate_

colon ';', semicolon
  xt compile                ; compile an unnest onto end of colon def
  xt _exit
  xt d_semi
  exit

; ------------------------------------------------------------------------
; add handler for a syscall

;       ( #params sys# --- )

colon 'syscall', syscall_
  xt create                 ; create the syscall handler word
  xt c_comma                ; compile in its syscall number
  xt c_comma                ; compile in parameter count
  xt s_uses                 ; patch new word to use dosyscall
  xt do_syscall
  exit

; ------------------------------------------------------------------------
; create handler for singlan sig#

;       ( addr sig# --- )

;colon 'signal', signal
;  dd create, here, bodyto   ;create and point to cfa of new word
;  dd suses, do_signal
;  dd rot, comma             ;compile address of signal handler
;  dd swap, sys_signal       ;make cfa a handler for specified signal
;  exit

; ========================================================================
