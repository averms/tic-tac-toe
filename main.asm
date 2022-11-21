.data
	prompt_mode: .asciiz "Play vs. 1=CPU or 2=User: "
	prompt_row: .asciiz "Row (1-3): "
	prompt_col: .asciiz "Col (1-3): "
	underscore: .ascii "_"
	space: .ascii " "
	line_feed: .ascii "\n"
	board: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0

.eqv BOARD_ROW_SIZE 3
.eqv BOARD_SIZE 9

.text
main:
	la	$a0, prompt_mode
	jal	get_int		# Prompt user for mode.
	move	$s0, $v0
	jal	display_board
	la	$v0, 10
	syscall			# Quit.


get_int:			# (addr of prompt) -> (read integer)
	li	$v0, 4
	syscall
	li	$v0, 5
	syscall
	jr	$ra


display_board:			# () -> ()
	li	$t0, 0
db_for:
	bge	$t0, BOARD_SIZE, db_end
	lbu	$a0, board($t0)
	li	$v0, 1
	syscall
	add	$t1, $t0, 1
	rem	$t1, $t1, BOARD_ROW_SIZE
	# Print line feed every row, when ($t0 + 1) mod 3 == 0.
	bne	$t1, 0, db_for_next
	lbu	$a0, line_feed
	li	$v0, 11
	syscall
db_for_next:
	addi	$t0, $t0, 1
	j	db_for
db_end:
	jr	$ra
