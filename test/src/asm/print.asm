%include "print.inc"

segment .data

	mes db 'Press any key',0xA
	len equ $-mes

segment .text
	global _print
_print:
	mov rax, 4
	mov rbx, 1
	mov rcx, mes
	mov rdx, len
	int 0x80

	mov rax, 1
	mov rbx, 0
	int 0x80
