; syscalls.s     - x4 linux syscall interface words
; ------------------------------------------------------------------------

; ------------------------------------------------------------------------

  _var_ 'errno', errno, 0

; ------------------------------------------------------------------------

sys_6:
  mov r9, qword [SP + 5* CELL]

sys_5:
  mov r8, qword [SP + 4* CELL]

sys_4:
  mov r10, qword [SP + 3* CELL]

sys_3:
  mov rdx, qword [SP + 2* CELL]

sys_2:
  mov rsi, qword [SP + CELL]

sys_1:
  mov rdi, [SP]
  lea SP, [SP + CELL * rbx]

; ------------------------------------------------------------------------
; syscall that takes no parameters (or we already have them)

;       ( --- n1 | false )

sys_0:
  syscall                   ; do syscall eax
  cmp rax, 0xfffffffffffff000
  jbe .L1                   ; did an error occurr?

  ; oopts - something fubared!

  neg rax                   ; get errno value
  mov qword [errno_b], rax  ; set errno value for caller to handle
  mov rax, -1               ; tell caller something fubared

.L1:
  mov rbx, rax              ; top of parameter stack
  next

; ------------------------------------------------------------------------
; table of syscall handlers for different number of parameters

sys_exe:
  dq sys_0, sys_1, sys_2, sys_3, sys_4, sys_5, sys_6

; ------------------------------------------------------------------------
; all syscalls go through here

;       ( a1 --- n1 | false )

do_syscall:
  apush rbx
  pop rbx                   ; get body address of syscall word (a1)
  movzx eax, byte [rbx]     ; get syscall number from body
  movzx ebx, byte [rbx + 1] ; get number of parameters for this call
  jmp [sys_exe +8* rbx]     ; do syscall

;-------------------------------------------------------------------------
; todo: might not be in a working state

;code 'do-signal', do_signal
;  pushad                    ; save all registers
;  mov rax, rsp
;  mov rsi, sigx             ; make handler exit to sigx
;  mov rax, [rax + 32]       ; get address of pointer to handler
;  jmp [rax]                 ; jump into handler
;
;sigx:
;  dq $+4                    ; a psudo forth execution token
;  popad
;  add rsp, CELL
;  ret

; ------------------------------------------------------------------------
; only defining syscalls that the kernel needs.

  _syscall_ '<exit>',   sys_exit,     60, 1
  _syscall_ '<read>',   sys_read,      0, 3
  _syscall_ '<write>',  sys_write,     1, 3
  _syscall_ '<open>',   sys_open,      2, 3
  _syscall_ '<close>',  sys_close,     3, 1
  _syscall_ '<creat>',  sys_creat,     8, 2
  _syscall_ '<ioctl>',  sys_ioctl,    16, 3
  _syscall_ '<poll>',   sys_poll,      7, 3
  _syscall_ '<lseek>',  sys_lseek,     8, 3
  _syscall_ '<mmap>',   sys_mmap,      9, 6
  _syscall_ '<munmap>', sys_munmap,   11, 2

;=========================================================================
