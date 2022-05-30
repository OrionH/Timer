STDIN equ 0
STDOUT equ 1
STDERR equ 2

SYS_READ equ 0
SYS_WRITE equ 1
NANOSLEEP equ 35
SYS_EXIT equ 60


%macro exit 0
        mov rax, SYS_EXIT
        mov rdi, 0              ; error code
        syscall
%endmacro

%macro print 2                  ; Input: string, string_len
        mov rax, SYS_WRITE
        mov rdi, STDOUT
        mov rsi, %1             ; string
        mov rdx, %2             ; string_len
        syscall
%endmacro

%macro nanosleep 1
	mov rax, NANOSLEEP	; nanosleep id
	mov rdi, %1		; length
	syscall
%endmacro	
