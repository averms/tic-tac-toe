.data
	prompt_mode: .asciiz "Play vs. 1=CPU or 2=User: "
	prompt_row: .asciiz "Row (1-3) from top: "
	prompt_col: .asciiz "Col (1-3) from left: "
	underscore: .ascii "_"
	space: .ascii " "
	line_feed: .ascii "\n"
	board: .byte 1, 2, 2, 2, 1, 0, 2, 1, 2

.eqv BOARD_ROW_SIZE 3
.eqv BOARD_SIZE 9
.eqv EMPTY 0
.eqv PLAYER1 1
.eqv PLAYER2 2

.text
main:
	la	$a0, prompt_mode
	jal	get_int		# Prompt user for mode.
	move	$s0, $v0
	jal	display_board
	jal	get_game_state
	li	$v0, 10
	syscall			# Quit.


get_int:
	# Takes: address of prompt string.
	# Gives: entered integer.
	li	$v0, 4
	syscall
	li	$v0, 5
	syscall
	jr	$ra


display_board:
	# Takes: nothing.
	# Gives: nothing except displaying the board.
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


get_game_state:
	# Takes: nothing.
	# Gives: 0 if game is still going and no winner
	#        1 if player1 won
	#        2 if player2 won
	#        3 if draw.
	addi	$sp, $sp, -8
	sw	$s0, 4($sp)
	sw	$ra, 0($sp)

ggs_mid:
	li	$a0, 1
	li	$a1, 1
	jal	index_board
	move	$s0, $v0
	beq	$s0, EMPTY, ggs_upleft
ggs_mid_diag:
	li	$a0, 0
	li	$a1, 0
	jal	index_board
	bne	$s0, $v0, ggs_mid_alt_diag
	li	$a0, 2
	li	$a1, 2
	jal	index_board
	beq	$s0, $v0, ggs_winner
ggs_mid_alt_diag:
	li	$a0, 2
	li	$a1, 0
	jal	index_board
	bne	$s0, $v0, ggs_mid_hori
	li	$a0, 0
	li	$a1, 2
	jal	index_board
	beq	$s0, $v0, ggs_winner
ggs_mid_hori:
	li	$a0, 1
	li	$a1, 0
	jal	index_board
	bne	$s0, $v0, ggs_mid_vert
	li	$a0, 1
	li	$a1, 2
	jal	index_board
	beq	$s0, $v0, ggs_winner
ggs_mid_vert:
	li	$a0, 0
	li	$a1, 1
	jal	index_board
	bne	$s0, $v0, ggs_upleft
	li	$a0, 2
	li	$a1, 1
	jal	index_board
	beq	$s0, $v0, ggs_winner

ggs_upleft:
	li	$a0, 0
	li	$a1, 0
	jal	index_board
	move	$s0, $v0
	beq	$s0, EMPTY, ggs_loright
ggs_upleft_hori:
	li	$a0, 0
	li	$a1, 1
	jal	index_board
	bne	$s0, $v0, ggs_upleft_vert
	li	$a0, 0
	li	$a0, 2
	jal	index_board
	beq	$s0, $v0, ggs_winner
ggs_upleft_vert:
	li	$a0, 1
	li	$a1, 0
	jal	index_board
	bne	$s0, $v0, ggs_loright
	li	$a0, 2
	li	$a0, 0
	jal	index_board
	beq	$s0, $v0, ggs_winner

ggs_loright:
	li	$a0, 2
	li	$a1, 2
	jal	index_board
	move	$s0, $v0
	beq	$s0, EMPTY, ggs_nowinner
ggs_loright_hori:
	li	$a0, 2
	li	$a1, 1
	jal	index_board
	bne	$s0, $v0, ggs_loright_vert
	li	$a0, 2
	li	$a0, 0
	jal	index_board
	beq	$s0, $v0, ggs_winner
ggs_loright_vert:
	li	$a0, 1
	li	$a1, 2
	jal	index_board
	bne	$s0, $v0, ggs_nowinner
	li	$a0, 0
	li	$a0, 2
	jal	index_board
	beq	$s0, $v0, ggs_winner
ggs_nowinner:
	jal	is_filled
	beq	$v0, 1, ggs_draw
	li	$v0, 0
	j	ggs_end
ggs_draw:
	li	$v0, 3
	j	ggs_end
ggs_winner:
	# Value in $s0 is PLAYER1 or PLAYER2, whichever won
	move	$v0, $s0
ggs_end:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra


is_filled:
	# Takes: nothing.
	# Gives: 1 if every spot is filled, 0 if not
	li	$t0, 0
if_for:
	bge	$t0, BOARD_SIZE, if_end
	lbu	$t1, board($t0)
	bne	$t1, EMPTY, if_for_next
	li	$v0, 0
	jr	$ra
if_for_next:
	addi	$t0, $t0, 1
	j	if_for
if_end:
	li	$v0, 1
	jr	$ra


index_board:
	# Takes: two word-length indicies
	# Gives: unsigned byte EMPTY, PLAYER1, or PLAYER2
	mul	$t0, $a0, BOARD_ROW_SIZE
	add	$t0, $t0, $a1
	lbu	$v0, board($t0)
	jr	$ra
