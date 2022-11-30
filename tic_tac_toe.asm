.data
    prompt_mode:    .asciiz "Play vs. 1=CPU or 2=User: "
    prompt_row:     .asciiz "Row (1-3) from top: "
	  prompt_col:     .asciiz "Col (1-3) from left: "
    prompt_redo:    .asciiz "WARNING: Square not empty\n"
    display_play1:  .asciiz "Congrats player 1! You are the winner!\n"
    display_play2:  .asciiz "Congrats player 2! You are the winner!\n"
    display_cpu:    .asciiz "Oops! Looks like you lost, try again!\n"
    display_tie:    .asciiz "Wow! Looks like a tie, try again!\n"
    underscore:     .asciiz "_"
    space:          .asciiz " "
    newline:        .asciiz "\n"
    player1:        .byte 1
    player2:        .byte 2
    board:          .byte 0, 0, 0, 0, 0, 0, 0, 0, 0

.eqv BOARD_ROW_SIZE 3
.eqv BOARD_SIZE 9
.eqv EMPTY 0
.eqv PLAYER1 1
.eqv PLAYER2 2

.text
fun_init:
    li 	$s0, 0 # reset playing mode
    li 	$s1, 0 # reset game result

    # reset game board
    la      $t0, board
    li      $t1, 0
    reset_board:
        addi    $t0, $t0, 1
        sb      $zero, 0($t0)

        addi    $t1, $t1, 1
        blt     $t1, 9, reset_board
        j       fun_main # begin game



fun_main:
    jal     fun_get_mode
    jal     display_board

    play_game:
        user1_move:
            jal     fun_get_user_input
            lbu     $t0, player1
            sb      $t0, 0($v1) # fill square

            jal     display_board

            # TODO CHECK IF GAME DONE !!!!!!!!!!!!

            bne     $s1, $zero, finish_game # game is done
            beq     $s0, 1, cpu_move
            j       user2_move
        
        user2_move:
            jal     fun_get_user_input
            lbu     $t0, player2
            sb      $t0, 0($v1) # fill square

            jal     display_board

            # TODO CHECK IF GAME DONE !!!!!!!!!!!!

            bne     $s1, $zero, finish_game # game is done
            j       user1_move

        cpu_move:
            jal     fun_get_cpu_move
            lbu     $t0, player2
            sb      $t0, 0($v1) # fill square

            jal     display_board

            # TODO CHECK IF GAME DONE !!!!!!!

            bne     $s1, $zero, finish_game # game is done
            j       user1_move

    finish_game:    # TODO NEEDS TESTING
        beq     $s1, 2, print_player2
        la      $a0, cong_player1

        print_player2:
            beq     $s0, 2, congrat_player2
            la      $a0, cong_cpu

            congrat_player2:
                la      $a0, cong_player2

        li      $v0, 4
        syscall

    j fun_init # restart game?



fun_get_user_input:
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    get_row:
        la      $a0, prompt_row
        jal     get_int
        move    $a1, $v0
        bgt     $a1, 3, get_row # check input
        blt     $a1, 1, get_row
        j       get_col

    get_col:
        la      $a0, prompt_col
        jal     get_int
        move    $a2, $v0
        bgt     $a2, 3, get_col # check input
        blt     $a2, 1, get_col

        addi    $a1, $a1, -1
        jal     get_element
        lb      $t0, 0($v1) # $t0 = current element
        bne     $t0, $zero, warn_user # square is filled

        lw      $ra, 0($sp)
        addi    $sp, $sp, 4
        jr      $ra

    warn_user:
        la      $a0, prompt_redo
        li      $v0, 4
        syscall
        j       get_row



fun_get_cpu_move:
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    gen_index:
        jal     get_rand_int
        move    $a1, $a0 # get row index
        jal     get_rand_int
        move    $a2, $a0, # get col index
        addi    $a2, $a2, 1

        jal     get_element
        lb      $t0, 0($v1) #t0 = current element
        bne     $t0, $zero, gen_index # square is filled

        lw      $ra, 0($sp)
        addi    $sp, $sp, 4
        jr      $ra



fun_get_mode:
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    ask_mode:   # ask user for playing mode
        la      $a0, prompt_mode
        jal     get_int
        move    $s0, $v0
        j       check_mode

    check_mode: # check for valid input
        bgt     $s0, 2, ask_mode
        blt     $s0, 1, ask_mode

        lw      $ra, 0($sp)
        addi    $sp, $sp, 4
        jr      $ra



get_rand_int:
    addi    $sp, $sp, -4
    sw      $a1, 0($sp)

    addi    $a1, $zero, 3 # upper bound = 3
    addi    $v0, $zero, 42 # generate rand int
    syscall

    lw      $a1, 0($sp)
    addi    $sp, $sp, 4
    jr 	    $ra



get_element:
    mul     $t0, $a1, 3 # index = row index * 3
    add     $t0, $t0, $a2 # index += col index

    la      $v1, board
    add     $v1, $v1, $t0
    jr      $ra



get_int:    # $a0 is the prompt, $v0 is the read integer.
    li      $v0, 4
    syscall
    li      $v0, 5
    syscall
    jr      $ra


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