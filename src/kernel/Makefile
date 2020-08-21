
list     = -l../kernel.lst
debug    = -g

flags = $(debug) $(list) -felf64

kernel: kernel.o
	@ld kernel.ld ../kernel.o -o ../../kernel
	@strip -R .comment ../../kernel

kernel.o: x64.asm
	@nasm $(flags) x64.asm -o ../kernel.o
