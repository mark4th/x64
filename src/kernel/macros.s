; macros.1       - x4 macro definitions
; ------------------------------------------------------------------------

%define ALIAS 0x20          ; lex flag: mark word as alias
%define IMM   0x40          ; lex flag: mark word as immediate
%define LEX   0x1f          ; mask to remove lex bits from cfa length
%define CELL  8             ; size of once memory cell
%define BODY  5             ; length of cfa = 5 bytes for call opcode
%define MEMSZ 0x100000      ; one meg
%define STKSZ 0x1000        ; 4k (return stack size)
%define FLDSZ 36 * 5        ; fload stack size (5 nested floads max)
%define TIBSZ 0x400         ; terminal input buffer size

%define RP r15
%define SP r14

; ------------------------------------------------------------------------

%xdefine imm 0              ; set to $40 to make next word immediate
%xdefine inl 0              ; set to $80 to make next definiation inlienable

%xdefine v_link 0           ; link to previous word in vocabulary

%xdefine f_link 0           ; link to previous word in forth vocab
%xdefine c_link 0           ; link to previous word in compiler vocab
%xdefine r_link 0           ; link to previous word in root vocab

%xdefine voc 0              ; currently linking to forth vocabulary

%define inline_exit 1

; ------------------------------------------------------------------------
; define 'next' macro

;   [rsp] is IP in this forth

%macro next 0
  ret
%endmacro

; ------------------------------------------------------------------------

%if(inline_exit = 1)
  %macro exit 0
    rpop rax
    jmp rax
  %endmacro
%elif
  %macro exit 0
    xt _exit
  %endmacro
%endif

; ------------------------------------------------------------------------
; make next assembled word an immediate word

%macro _immediate_ 0
  %xdefine imm IMM
%endmacro

; ------------------------------------------------------------------------
; push item onto arg (parameter) stack or return stack

%macro apush 1
  xchg SP, rsp
  push %1
  xchg SP, rsp
%endmacro

%macro apush2 2
  xchg SP, rsp
  push %1
  push %2
  xchg SP, rsp
%endmacro

%macro apush3 3
  xchg SP, rsp
  push %1
  push %2
  push %3
  xchg SP, rsp
%endmacro

%macro apop 1
  xchg SP, rsp
  pop %1
  xchg SP, rsp
%endmacro

%macro apop2 2
  xchg SP, rsp
  pop %1
  pop %2
  xchg SP, rsp
%endmacro

%macro rpush 1
  xchg RP, rsp
  push %1
  xchg RP, rsp
%endmacro

%macro rpush2 2
  xchg RP, rsp
  push %1
  push %2
  xchg RP, rsp
%endmacro

%macro rpop 1
  xchg RP, rsp
  pop %1
  xchg RP, rsp
%endmacro

%macro rpop2 2
  xchg RP, rsp
  pop %1
  pop %2
  xchg RP, rsp
%endmacro

; ------------------------------------------------------------------------
; compile an xt (execution token) which is just a call opcode

%macro xt 1
  call  %1
%endmacro

; ------------------------------------------------------------------------
; compile a branch vector which is a 16 bit relative delta

%macro bv 1
  dw (%1 - $)
%endmacro

; ------------------------------------------------------------------------

%macro literal 1
  apush rbx
  mov rbx, %1
%endmacro

; ------------------------------------------------------------------------
; sub macro to compile headers for forth words.

%macro header 2
[section headers]
  dq v_link                 ; link to previous word in vocabulary
%%link:
%2_n:
%xdefine v_link %%link
  db (%%name-$-1)+imm       ; name length + flags
  db %1                     ; name
%%name:
  dq %2                     ; pointer to cfa (in .data section)
%xdefine imm 0
[section .text]
  dq %%link                 ; cfa -4 points to nfa
%endmacro

; ------------------------------------------------------------------------
; compile a header in head space for a coded definition

%macro code 2
  header %1, %2             ; create header in head space
%2:                         ; make label for new coded definition
%endmacro

; ------------------------------------------------------------------------
; compile a header in head space for a high level definition

%macro colon 2
  header %1, %2             ; create header which will point at
%2:                         ; this label as its code vector
  call nest                 ; stack juggling ensues here
%endmacro

; ------------------------------------------------------------------------
; construct a forth variable

%macro _variable_ 3
  code %1, %2
  call do_variable
%2_b:
  dq %3
%endmacro

; ------------------------------------------------------------------------
; construct a forth constant

%macro _constant_ 3
  code %1, %2
  call do_constant
%2_b:
  dq %3
%endmacro

; ------------------------------------------------------------------------
; construct a forth var (like value but with a descriptive name)

%macro _var_ 3
  code %1, %2
  call do_constant
%2_b:
  dq %3
%endmacro

; ------------------------------------------------------------------------

%macro _defer_ 3
  code %1, %2
  call do_defer
%2_b:
  dq %3
%endmacro

; ------------------------------------------------------------------------
; macro - create a syscall word

%macro _syscall_ 4
  code %1, %2
  call do_syscall
%2_b:
  db %3, %4
%endmacro

; ------------------------------------------------------------------------

%macro _vocab_ 4
  code %1, %2
  call do_voc
%2_b:
  dq %3
  times 63 dq 0
  dq %4
%endmacro

; ------------------------------------------------------------------------
; save voclink to current vocabs link variable

%macro save_link 0
 %if(voc = 0)               ; were we linking on the forth vocabulary ?
  %xdefine f_link v_link    ; yes - set new end of forth vocab
 %elif(voc = 1)             ; were we linking on the compiler vocabulary ?
  %xdefine c_link v_link    ; yes - set new end of compiler vocab
 %else
  %xdefine r_link v_link    ; musta been root vocab then. set new end
 %endif
%endmacro

; ------------------------------------------------------------------------
; link all new definitions to the forth vocabulary

%macro _forth_ 0
 save_link                  ; save link address of previous vocabulary
 %xdefine v_link f_link     ; start linking on forth vocabulary
 %define voc 0
%endmacro

; ------------------------------------------------------------------------
; link all new definitions to the compiler vocabulary

%macro _compiler_ 0
 save_link                  ; save link address of previous vocabulary
 %xdefine v_link c_link     ; start linking on compiler vocabulary
 %define voc 1
%endmacro

; ------------------------------------------------------------------------
; link all new definitions to the root vocabulary

%macro _root_ 0
 save_link                  ; save link address of previous vocabulary
 %xdefine v_link r_link     ; start linking on root vocabulary
 %xdefine voc 2
%endmacro

; ========================================================================
