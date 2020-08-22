; x64.asm
; ------------------------------------------------------------------------

  bits 64

  %define ver $0001

; ------------------------------------------------------------------------

  %include "macros.s"

; ------------------------------------------------------------------------

  [section .text]
  global origin

; ------------------------------------------------------------------------

origin:
  jmp init

; ------------------------------------------------------------------------

  _forth_

  _constant_ 'origin', org, origin
  _constant_ 'version', version, ver
  _constant_ 'thead', t_head, 0
  _constant_ 'head0', b_head, 0

  _constant_ 'arg0', arg0, 0
  _constant_ 'argc', argc, 0
  _constant_ 'argp', argp, 0
  _constant_ 'envp', envp, 0
  _constant_ 'auxp', auxp, 0

  _constant_ '?#!', q_shebang, 0
  _constant_ 'in-tty', in_tty, 0
  _constant_ 'out-tty', out_tty, 0

; ------------------------------------------------------------------------

  _var_ 'heap-prot', heap_prot, 3
  _var_ 'heap-flags', heap_flags, 0x22

; ------------------------------------------------------------------------

  _constant_ 'turnkeyd', turnkeyd, 0
  _variable_ '?tty', q_tty, 0

; ------------------------------------------------------------------------

  _defer_ 'pdefault', _pdefault, noop
  _defer_ 'default', _default, noop
  _defer_ 'ldefault', _ldefault, rehash

  _defer_ 'atexit', at_exit, noop

  _defer_ '.s', dots, noop
  _defer_ '.us', dotus, noop

; ------------------------------------------------------------------------

;  rbx = length
;  r10 = flags
;  rdx = prot

_fetch_map:
  mov rdi, 0                ; address
  mov r8, -1                ; fd (setting to -1 is more portable)
  mov r9, 0                 ; offset = 0
  mov rsi, rbx              ; length of mapping

  mov rax, 9
  syscall
  ret

; ------------------------------------------------------------------------

code '@map', fmap
  mov rdx, qword [heap_prot_b]
  mov r10, qword [heap_flags_b]
  call _fetch_map
  cmp rax, 0xfffffffffffff000
  jbe .L1
  mov ebx, -1
  next
.L1:
  apush rax
  xor rbx, rbx
  next

; ------------------------------------------------------------------------

  %include "syscalls.s"
  %include "stack.s"
  %include "memory.s"
  %include "logic.s"
  %include "double.s"
  %include "math.s"
  %include "exec.s"
  %include "loops.s"
  %include "io.s"
  %include "number.s"
  %include "scan.s"
  %include "expect.s"
  %include "parse.s"

; ------------------------------------------------------------------------

  _compiler_

  %include "comment.s"
  %include "find.s"
  %include "header.s"
  %include "comma.s"
  %include "compile.s"
  %include "fload.s"
  %include "interpret.s"

; ------------------------------------------------------------------------

  _root_

  %include "reloc.s"
  %include "vocabs.s"
  %include "rehash.s"

; ------------------------------------------------------------------------
; do not define any words below this point unless they are 100% headerless
; ------------------------------------------------------------------------

  %include "init.s"         ; forth initialization

;-------------------------------------------------------------------------
;marks end of code space (where boot will set dp pointing to)

;note:   do not define anything at all below this point

_end:                       ; when x4 loads, this is where headers are

; ========================================================================
