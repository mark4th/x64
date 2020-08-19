; init.s    - initialize forth environment
; ------------------------------------------------------------------------

  _var_ "psp0", psp0, 0       ; state of processor stack at init

; ------------------------------------------------------------------------
; allocate return stack of 4k (one page)

;  rbx = length
;  r10 = flags
;  rdx = prot

alloc_stacks:
  push rdi
  mov rbx, STKSZ * 2        ; length of mapping
  mov r10, 0x22             ; anonymous private
  mov edx, 3                ; prot read/write
  call _fetch_map
  add rax, STKSZ            ; point to top of buffer we just allocated
  mov [rp0_b], rax          ; set address of bottom of return stack
  add rax, STKSZ - CELL     ; point to top of buffer we just allocated
  mov [sp0_b], rax          ; set address of bottom of parameter stack
  pop rdi
  ret

; ------------------------------------------------------------------------
; prepare forths process space,  (make it ALL +rwx }:)

init_mem:
  mov rsi, MEMSZ            ; for entire range of memory from rdi to memsz
  mov rdx, 7                ; +r +w +x
  mov rax, 10               ; sys mprotect
  syscall                   ; make the entire program space rwx
  ret

; ------------------------------------------------------------------------

init_vars:
  mov qword [q_tty_b], 0    ; terminal properties not set yet
  mov qword [q_shebang_b], 0  ; not running as a script

  mov rax, rdi              ; set fload nest stack at end of memory
  add rax, MEMSZ-1-FLDSZ
  mov qword [lsp_b], rax    ; dont nest floads!!!

  sub rax, TIBSZ            ; 1k for terminal input
  mov qword [tib_b], rax
  dec rax

  mov qword [t_head_b], rax ; mark upper bounds of head space

  mov rax, rdi              ; set address of top of list space
  add rax, MEMSZ / 2        ; split mem in 2
  add rax, 0x3ff
  and rax, -0x400
  mov qword [hp_b], rax     ; address for headers to be relocated to
  mov qword [b_head_b], rax ; needed by fsave - bottom of head space
  ret

; ------------------------------------------------------------------------

get_args:
  pop rdx                   ; our return address (bleh)
  xor rax, rax

  mov qword [argp_b], rax   ; pointer to argv[]
  mov qword [envp_b], rax   ; pointer to envp[]
  mov qword [auxp_b], rax   ; pointer to auxp[]

  pop rcx                   ; argc
  pop qword [arg0_b]        ; program name
  mov qword [argp_b], rsp
  lea rsi, [rsp +8* rcx]    ; point to env vars
  dec rcx
  mov qword [argc_b], rcx   ; set argc
  mov qword [envp_b], rsi   ; scan to end of env vars
.L0:
  lodsq
  cmp rax, 0
  jne .L0
  inc rsi
  mov qword [auxp_b], rsi   ; point to aux vectors
  jmp rdx

; ------------------------------------------------------------------------
; not required but keeps users list space clean at start of world

clr_mem:
  mov rdi, qword [dp_b]     ; erase list space
  mov rcx, qword [b_head_b] ; address at top of list space plus 1
  sub rcx, rdi
  xor rax, rax
  rep stosb                 ; erase entire unused part of list space
  ret

; ------------------------------------------------------------------------
; test if fd in ebx is a tty. return result in eax

_chk_tty:
  mov eax, 0x10             ; ioctl
  mov esi, 0x5401           ; tcgets
  mov rdx, qword [dp_b]     ; here
  syscall                   ; is handle ebx a tty?
  sub rax, 1
  sbb rax, rax              ; 0 = fales. -1 = true
  ret

; ------------------------------------------------------------------------

chk_tty:
  xor rdi, rdi              ; stdin
  call _chk_tty             ; test fd ebx = tty
  mov qword [in_tty_b], rax ; store result for stdin

  mov rdi, 1                ; stdout
  call _chk_tty             ; get parameters for syscall
  mov qword [out_tty_b], rax; store result for stdout
  ret

; ------------------------------------------------------------------------
; entry point of process is a jump to this address

init:
  mov rdi, origin           ; get address of start of .text section
  and rdi, 0xffffffffffff8000

  ; rdi now points to the 0th byte of process memory which also happens to
  ; be the address of the programs elf headers.

  call init_mem             ; sys_brk out to 1m and sys_mprotect to rwx
  call alloc_stacks         ; allocate return stack
  call init_vars            ; initialize some forth variables
  call get_args             ; set address of argp envp etc
  call unpack               ; relocate headers to allocated head space
  call chk_tty              ; chk if stdin/out are on a terminal
  call clr_mem              ; erase as yet unused list space

  mov qword [psp0_b], rsp

  mov SP, qword [sp0_b]     ; NOW we can start running forth
  mov RP, qword [rp0_b]     ; so set its stack pointers

  xt _pdefault              ; hi priority defered init chain
  xt _default               ; std priority defered init chain
  xt _ldefault              ; low priority deferred init chain

  xt quit                   ; run inner loop - never returns

; ========================================================================
