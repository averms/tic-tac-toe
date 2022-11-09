.data
	prompt_mode: .asciiz "Play vs. 1=CPU or 2=User: "
	prompt_row: .asciiz "Row (1-3): "
	prompt_col: .asciiz "Col (1-3): "
	underscore: .asciiz "_"
	space: .asciiz " "
	board: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0
.text
main:
	la	$a0, prompt_mode
	jal	fun_get_int
	move	$s0, v0		# save playing mode.
	la	$v0, 10		# exit
	syscall

fun_get_int:			# $a0 is the prompt, $v0 is the read integer.
	li	$v0, 4
	syscall
	li	$v0, 5
	syscall
	jr	$ra
