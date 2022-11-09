.data
	prompt_mode: .asciiz "Play vs. 1=CPU or 2=User: "
	prompt_row: .asciiz "Row (1-3): "
	prompt_col: .asciiz "Col (1-3): "
	underscore: .asciiz "_"
	space: .asciiz " "
	newline: .asciiz "\n"
	board: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0
.text
main:
	la	$a0, prompt_mode
	jal	fun_get_int
	move	$s0, $v0	# save playing mode
	
	jal fun_display_board	
	
	la	$v0, 10		# exit
	syscall

fun_get_int:			# $a0 is the prompt, $v0 is the read integer.
	li	$v0, 4
	syscall
	li	$v0, 5
	syscall
	jr	$ra

fun_display_board:
	addi	$sp, $sp, -8
	sw	$ra, 0($sp)

	addi 	$t0, $t0, 0 # curr index
	la 	$t1, board # board address
	
	loop_board:
		add 	$t1, $t1, $t0
		lb  	$a0, 0($t1)
		li 	$v0, 1
		syscall
		
		add 	$t2, $t0, 1
		rem 	$t2, $t2, 3
		
		bne 	$t2, 0, skip_newline
		la 	$a0, newline
		li 	$v0, 4
		syscall
		
	skip_newline:
		addi 	$t0, $t0, 1
		bge 	$t0, 9, exit_loop
		j 	loop_board
	
	exit_loop:
		lw 	$ra, 0($sp)
		jr 	$ra
		
	
	
