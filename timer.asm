%include "helpers.inc"

section .data
	format db "Timer format is (name), hours, minutes, seconds ((16b) 00 00 00)", 10, 0
	len_format equ $ - format
	format2 db "All operands are requred except for name. All operands have to be 60 or less.",10,0
	len_format2 equ $ - format2
	headerText db " timer set for: "
	len_headerText equ $ - headerText
	hoursText db " hour(s) "
	len_hoursText equ $ - hoursText
	minutesText db " minute(s) "
	len_minutesText equ $ - minutesText
	secondsText db " second(s) "
	len_secondsText equ $ - secondsText
	timerEnd db "Timer finished"
	len_timerEnd equ $ - timerEnd
	timer db "Timer: "
	len_timer equ $ - timer
	NL db 10					; newline
	CR db 13					; carriage return
	bell db 07					; bell


section .bss
	integerAsString resb 22		; largest unsigned 64bit number is 20 digits + /n + /0
	IASPosition resb 8			; position tracker for printIntegerRAX subroutine. 8 bytes to hold register

	stringToInt resb 8			; variable to hold address when converting string to int

	name resb 16				; variables to hold string input arguments
	hours resb 3
	minutes resb 3
	seconds resb 3

	ihours resb 1				; variables to hold integer input arguments
	iminutes resb 1
	iseconds resb 1

	argc resb 2					; argument count


section .text
	global _start				; for linker
_start:							; entry point (main)

	call _loadArguments			; load command line arguments
	call _printHeader			; print how long the timer will run
	call _convertArgsatoi		; convert input args to integers
	call _countdown				; countdown to 0 from args input
	exit


_loadArguments:					; load command line arguments
	pop rdx						; save return pointer
								; get each argument and convert to the string value rather than address
	pop rax						; get arg count
	mov [argc], al
	pop rbx 					; pop off path pointer
	cmp al, 4					; check if name was input as an argument
	je _requiredArgs
	cmp al, 5
	jne _argWarning
	pop rax						; get name
	mov rcx, 15					; max length of name (1 less to account for /0)
	mov rsi, rax				; move source address into rsi
	mov rdi, name				; move destination address into rdi
	cld							; clear direction flag
	rep movsb					; repeate byte move for max length

_requiredArgs:					; args except for name
	pop rax						; get hours
	mov bx, [rax]
	mov [hours], bx
	pop rax						; get minutes
	mov bx, [rax]
	mov [minutes], bx
	pop rax						; get seconds
	mov bx, [rax]
	mov [seconds], bx			; saving value instead of address in 2 bytes truncates the inputs to <100
	push rdx					; restore return pointer
	ret


_argWarning:					; format or range warning for input args
	print format, len_format	; print input argument format
	print format2, len_format2	; print more info on input
	exit						; exit if input args don't match format
	ret


_convertArgsatoi:				; convert srting input args to integer and check if they match format
	mov rax, hours				; variables have to be in rax to be converted to int
	call _atoiRAX				; convert to int
	mov [ihours], rax			; save in new variable
	call _argCheckRAX			; check to make sure the number input isn't stupid

	mov rax, minutes		 	; convert minutes
	call _atoiRAX
	mov [iminutes], rax
	call _argCheckRAX

	mov rax, seconds			; convert seconds
	call _atoiRAX
	mov [iseconds], rax
	call _argCheckRAX
	ret


_argCheckRAX:					; check if input arg is in range
	cmp rax, 60					; check if input is over 60
	jg _argWarning
	cmp rax, 0					; check if input is under 0
	jl _argWarning
	ret


_printHeader:					; print information that was input via args
	mov rax, [argc]				; check whether to print a name
	cmp rax, 4
	je _printHeaderArgs
	cmp rax, 5
	je _printHeaderName

_printHeaderName:				; print out name input
	mov rax, name
	call _printStringRAX
_printHeaderArgs:				; call print macros for pieces of header
	print headerText, len_headerText
	print hours, 2
	print hoursText, len_hoursText
	print minutes, 2
	print minutesText, len_minutesText
	print seconds, 2
	print secondsText, len_secondsText
	print NL, 1
	ret


_printDynamicArgs:				; print out current timer args
	print CR, 1					; carriage return to write over current line
	print timer, len_timer
	mov rax, [rsp+24]			; get integers pushed to the stack
	call _printIntegerRAX
	print hoursText, len_hoursText
	mov rax, [rsp+16]
	call _printIntegerRAX
	print minutesText, len_minutesText
	mov rax, [rsp+8]			; start at +8 because of the function call pointer
	call _printIntegerRAX
	print secondsText, len_secondsText
	ret


_countdown:						; countdown from time input
	push rbp					; push the current base pointer to the stack
	mov rbp, rsp				; set the current stack frame since we will be using the stack later
	xor rax, rax				; set all decrement registers to 0
	xor rbx, rbx				; the xor method has a few reasons for being the best besides speed
	xor rcx, rcx

	mov al, [ihours]			; move saved variable values into decrement registers
	mov bl, [iminutes]
	mov cl, [iseconds]
	jmp _secondLoop				; countdown starting with seconds

_hourLoop:						; for looping through hours and checking end condition
	mov rdx, rax				; mov rax to rdx since the first operand recieves the or calculations
	or rdx, rbx					; merge together all decrement registers to check if they are all 0
	or rdx, rcx
	cmp rdx, 0					; check if all registers are 0
	jz _endLoop
	dec rax						; if more than 0, decrement and set minutes to 60
	mov rbx, 60
	jmp _minuteLoop
_minuteLoop:					; for looping through minutes
	cmp rbx, 0					; if 0, check to see if hours needs to be decremented
	je _hourLoop
	dec rbx						; if more than 0, decrement and set seconds to 60
	mov rcx, 60
	jmp _secondLoop
_secondLoop:					; for looping through seconds, sleeping, and printing time info
	cmp rcx, 0					; if 0, check to see if minutes needs to be decremented
	je _minuteLoop

	push rax					; save values before syscall and function calls change them
	push rbx
	push rcx

	call _printDynamicArgs 		; print out dynamic countdown line

	push 0						; push timestruct onto stack for nanosleep. Nanoseconds
	push 1						; seconds
	nanosleep rsp				; sleep 1 second
	pop rdi						; remove timestruct values from stack
	pop rdi

	pop rcx						; retrieve values from stack
	pop rbx
	pop rax

	dec rcx						; countdown 1 second
	jmp _secondLoop

_endLoop:						; when all values are 0
	push 0						; push values for printdynamicArgs
	push 0						; print out args one more time or the timer will be left at 1 second
	push 0
	call _printDynamicArgs
	print NL, 1					; printer timer end message
	print timerEnd, len_timerEnd
	print bell, 1				; play beep if terminal is capable
	print NL, 1
	mov rsp, rbp				; reset stack frame
	pop rbp
	ret


_atoiRAX:						; convert string at rax to int
	mov [stringToInt], rax		; save base address
	mov bl, [rax]
	cmp bl, 0					; empty string check
	jne _loopToEnd
	ret
_loopToEnd:						; loop till end of string
	inc rax
	mov bl, [rax]
	cmp bl, 0					; the way my variables are set up they will always end in \0
	jne _loopToEnd

	xor rdi, rdi				; initialize total xor method is used because it's fastest
	xor rdx, rdx				; initialize position counter aka 10s power.
	xor rcx, rcx				; initialize exponent counter

_addDigits:						; sum digit to total
	dec rax						; move back one byte from end of string to first digit
	mov bl, [rax]				; store digit in rbx
	sub bl, 48					; convert from ascii to hex
	cmp rdx, 0					; if the exponent of the digit is 0
	jg _exponentiation
	add rdi, rbx				; store the digit and don't perform multiplication
	inc rdx						; increase poisition counter
	cmp rax, [stringToInt]
	jg _addDigits
	mov rax, rdi				; return value at rax
	ret

_exponentiation:				; multipy digit by 10 n number of times base on position in string
	imul rbx, 10
	inc rcx						; increment power counter
	cmp rcx, rdx				; check if we have multiplied by 10 enough
	jl _exponentiation
	mov rcx, 0					; reset power counter
	inc rdx						; increase position counter
	add rdi, rbx				; add new multipied digit to total
	cmp rax, [stringToInt] 		; check if we have decremented to the base address
	jg _addDigits
	mov rax, rdi				; return value at rax
	ret


_printIntegerRAX:				; print an interer at rax
	mov rcx, integerAsString	; get variable address
	mov rbx, 0					; This string gets printed out in reverse so we put in a null char
	mov [rcx], rbx				; any characters that have to be at the end need to be put in first
	inc rcx						; move to next byte to place next character
	mov [IASPosition], rcx		; put  integerAsString address into temp variable

_integerLoop:					; loop through digits
	mov rdx, 0					; put 0 in rdx so division doesn't get messed up by concatonated register
	mov rbx, 10					; move 10 into rbx
	div rbx						; divide the integer by 10
	add rdx, 48					; convert remainder of division to char

	mov rcx, [IASPosition]		; get  address stored in temp var
	mov [rcx], dl				; can't affect memory so you modify the location in a register
	inc rcx
	mov [IASPosition], rcx

	cmp rax, 0					; check if the remainder is 0
	jne _integerLoop			; loop if not at the end of the integer

_integerPrintReverse:			; print stored digits in reverse order
	print rcx, 1				; call print macro

	mov rcx, [IASPosition]		; rcx altered by syscall so we reload the address into rcx
	dec rcx
	mov [IASPosition], rcx		; store new rcx address for next loop

	cmp rcx, integerAsString	; check if we have decremented to the base address of integerAsString
	jge _integerPrintReverse	; loop if not
	ret


_printStringRAX:				; subroutine to print out string at rax of unknown length
	push rax
	mov rbx, 0					; initialize counter
_stringLoop:					; loop through bytes
	inc rax
	inc rbx						; increment counter
	mov cl, [rax]				; move the character at rax into cl
	cmp cl, 0					; check if at the end of the string
	jne _stringLoop				; loop till end of the string

	pop rsi						; get original string from stack

	print rsi, rbx				; call print macro
	ret
