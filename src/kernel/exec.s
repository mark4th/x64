; exec.s         - x4 execution and interpretation words
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------

  _defer_ 'abort', abort,  p_abort

; ------------------------------------------------------------------------
; no operation

;       ( --- )

code 'noop', noop           ; no operation
  next

; -----------------------------------------------------------------------
; define a word with break in it and place bp there. execute that word
; and you are now breaked inside your new definition and can single step

code 'break', break         ; no operation
  next                      ; good place to put a breakpoint

; -----------------------------------------------------------------------
; belongs in src/ext/struct.f

code '(db)', p_db
  pop rax
  add rbx, qword [rax]
  next

; ------------------------------------------------------------------------

; at the time this word is called the processor stack will have three items
; on it in this order of push...
;
;  1: the return address to the word taht called the does> created word
;  2: the address of the body of the does> create word
;  3: the address of the code following does> in the creating word

code 'dodoes', dodoes
  pop rax               ; pop does> address
  apush rbx             ; save top of stacl
  pop rbx               ; pop body address of does word
  pop rcx               ; get return address of word that called does word
  rpush rcx             ; nest into does> part
  jmp rax

; ------------------------------------------------------------------------
; nest into a high level definition - called by : definition

;       ( a1 --- )

code 'nest', nest
  pop rcx                   ; we were called, a1 is under our return adderss
  sub RP, byte CELL         ; pop a1 into return stack
  pop qword [RP]
  jmp rcx

; ------------------------------------------------------------------------
; exit from current high level definition

;       ( --- )

code 'exit', _exit
  pop rax                  ; discard return address of exit
  rpop rax
  jmp rax

; ------------------------------------------------------------------------
; conditionally exit high level definition

;       ( f1 --- )

code '?exit', q_exit
  mov rax, rbx              ; keep f1 so we can test after pop
  apop rbx                  ; cache new tos (test result retained in psw)
  or rax, rax
  jnz _exit                 ; 0 = false, non 0 = not false, -1 = true :)
  next

; ------------------------------------------------------------------------
; vector to the n1th word in the list following exec:

; this word is an implied unnest from any word using it

;       ( n1 --- )

code 'exec:', exec_c
  pop rax                   ; point to array of xt's following exec:

  lea rbx, [rbx + 4* rbx]
  add rbx, rax              ; point to xt to be executed

  call xt_fetch             ; conert xt to absolute address
  push qword [RP]           ; unnest from word calling exec: now
  add RP, byte CELL

.L1:
  mov rax, rbx
  apop rbx                  ; cache new top of stac
  jmp rax                   ; execute n1th word after exec:

; ------------------------------------------------------------------------
; alternate for if dotrue else dofalse then

;       ( f1 --- )

code '?:', q_colon
  mov rax, [rsp]            ; point rax at true vecror
  add qword [rsp], 10       ; advance IP past true and false vectors

  xchg rax, rbx             ; bx = vectors, ax = f1

  cmp rax, 0                ; is f1 true or false
  jne .L1
  add rbx, byte 5           ; false: point bx at false vector

.L1:
  call xt_fetch             ; convert vectors call opcode to its absolute
  jmp exec_c.L1

; ------------------------------------------------------------------------
; execution time code for all constant (and var) definitions.

;       ( a1 --- n1 )

code 'doconstant', do_constant
  apush rbx
  pop rbx
  mov rbx, qword [rbx]
  next

; ------------------------------------------------------------------------
; execution time code for all variable definitions

;       ( a1 --- a1 )

code 'dovariable', do_variable
  apush rbx
  pop rbx
  next

; ------------------------------------------------------------------------
; cfa of defered word calls here

;       ( a1 --- )

code 'dodefer', do_defer
  pop rax                   ; get defered word execution vector
  jmp [rax]                 ; execute defered word

; ------------------------------------------------------------------------
; execute word whose code address is at top of stack

;       ( a1 --- )

code 'execute', execute
  mov rax, rbx
  apop rbx
  jmp rax

; ------------------------------------------------------------------------
; default execution vector for a defered word

;    : crash    ( --- )
;        true abort" crash!: ;

colon 'crash', crash
  apush rbx
  mov rbx, [rax - 13]
  xt count
  xt lex_mask
  xt type
  xt space

  xt true
  xt p_abort_q
  db 6, 'crash!'
  exit

; ------------------------------------------------------------------------
; quit x4 back to shell

;    : bye    ( --- )
;        atexit cr cr
;         ." Au Revoir!" cr cr
;         errno <exit> ;

colon 'bye', bye
  xt at_exit                ; run the exit chain
  xt cr
  xt cr
  xt p_dot_q
  db 10, 'Au Revoir!'
  xt cr
  xt cr
  xt errno
  xt sys_exit

; ========================================================================
