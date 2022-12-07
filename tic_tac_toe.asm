.data
    prompt_mode:    .asciiz "\nPlay vs. 1 = CPU or 2 = User: (Enter 1 or 2) "
    prompt_char:    .asciiz "Player 1 Character 1 = X or 2 = O: (Enter 1 or 2) "
    prompt_row:     .asciiz "Row (1-3) from top: "
    prompt_col:     .asciiz "Col (1-3) from left: "
    prompt_redo:    .asciiz "WARNING: Square occupied\n"
    prompt_player1: .asciiz "\nPlayer 1's Turn"
    prompt_player2: .asciiz "\nPlayer 2's Turn"

    display_CPU_turn: .asciiz "\nCPU's Turn"
    display_play1:   .asciiz "Congrats player 1! You are the winner!\n"
    display_play2:   .asciiz "Congrats player 2! You are the winner!\n"
    display_cpu:     .asciiz "Oops! Looks like you lost, try again!\n"
    display_tie:     .asciiz "Wow! Looks like a tie, try again!\n"

    underscore:     .asciiz "_"
    space:          .asciiz " "
    X:              .asciiz "X"
    O:              .asciiz "O"
    line_feed:      .asciiz "\n"

    player1:        .byte 1
    player2:        .byte 2
    board:          .byte 0, 0, 0, 0, 0, 0, 0, 0, 0

.eqv BOARD_ROW_SIZE 3
.eqv BOARD_SIZE 9
.eqv EMPTY 0
.eqv PLAYER1 1
.eqv PLAYER2 2

.text

init:
    # Input:  void
    # Output: void, resets game
    li 	$s0, 0 # reset playing mode
    li 	$s1, 0 # reset player characters

    # reset game board
    la      $t0, board
    li      $t1, 0
init_reset_board:
    sb      $zero, 0($t0)
    addi    $t0, $t0, 1
    addi    $t1, $t1, 1
    blt     $t1, BOARD_SIZE, init_reset_board
    j       main # begin game


main:
    # Input:  void
    # Output: void, runs the gameplay
    jal     get_game_mode
    jal     get_game_char

main_play_game:

pg_user1_move:

    la      $a0, prompt_player1
    li      $v0, 4
    syscall
    jal     display_board

    jal     get_user_input
    lbu     $t0, player1
    sb      $t0, 0($v0) # fill square

    jal     get_game_state
    bne     $v0, $zero, main_finish_game # game is done
    beq     $s0, 1, pg_cpu_move

pg_user2_move:

    la      $a0, prompt_player2
    li      $v0, 4
    syscall
    jal     display_board

    jal     get_user_input
    lbu     $t0, player2
    sb      $t0, 0($v0) # fill square

    jal     get_game_state
    bne     $v0, $zero, main_finish_game
    j       pg_user1_move

pg_cpu_move:

    la      $a0, display_CPU_turn
    li      $v0, 4
    syscall
    jal     display_board

    jal     get_cpu_move
    lbu     $t0, player2
    sb      $t0, 0($v0) # fill square

    jal     get_game_state
    bne     $v0, $zero, main_finish_game
    j       pg_user1_move

main_finish_game:
    jal     display_board

    beq     $v0, 2, fg_print_player2
    beq     $v0, 3, fg_print_tie

    la      $a0, display_play1
    j       fg_print_result

fg_print_player2:
    beq     $s0, 2, fg_congrat_player2
    la      $a0, display_cpu
    j       fg_print_result

fg_congrat_player2:
    la      $a0, display_play2
    j       fg_print_result

fg_print_tie:
    la      $a0, display_tie

fg_print_result:
    li      $v0, 4
    syscall
    j       init # restart game


get_game_mode:
    # Input:  void
    # Output: $s0 => game mode
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

ggm_ask_mode:
    # ask user for playing mode
    la      $a0, prompt_mode
    jal     get_int
    move    $s0, $v0

    # check for valid input
    bgt     $s0, PLAYER2, ggm_ask_mode
    blt     $s0, PLAYER1, ggm_ask_mode

    lw      $ra, 0($sp)
    addi    $sp, $sp, 4
    jr      $ra


get_game_char:
    # Input:  void
    # Output: $s1 => player characters
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

ggc_ask_char:
    # ask user for playing mode
    la      $a0, prompt_char
    jal     get_int
    move    $s1, $v0

    # check for valid input
    bgt     $s1, PLAYER2, ggc_ask_char
    blt     $s1, PLAYER1, ggc_ask_char

    lw      $ra, 0($sp)
    addi    $sp, $sp, 4
    jr      $ra


get_user_input:
    # Input:  void
    # Output: void, retrieves user for move
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

gui_get_row:
    la      $a0, prompt_row
    jal     get_int
    move    $a1, $v0
    bgt     $a1, BOARD_ROW_SIZE, gui_get_row # check input
    blt     $a1, 1, gui_get_row

gui_get_col:
    la      $a0, prompt_col
    jal     get_int
    move    $a2, $v0
    bgt     $a2, BOARD_ROW_SIZE, gui_get_col # check input
    blt     $a2, 1, gui_get_col
    
    addi    $a1, $a1, -1
    addi    $a2, $a2, -1
    jal     get_element
    lb      $t0, 0($v0)
    bne     $t0, EMPTY, gui_warn_user # square is filled

    lw      $ra, 0($sp)
    addi    $sp, $sp, 4
    jr      $ra

gui_warn_user:
    la      $a0, prompt_redo
    li      $v0, 4
    syscall
    j       gui_get_row


get_cpu_move:
    # Input:  void
    # Output: void, generates cpu move
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

gcm_gen_index:
    jal     get_rand_int
    move    $a1, $a0 # get row index
    jal     get_rand_int
    move    $a2, $a0, # get col index

    jal     get_element
    lb      $t0, 0($v0) #t0 = current element
    bne     $t0, EMPTY, gcm_gen_index # square is filled

    lw      $ra, 0($sp)
    addi    $sp, $sp, 4
    jr      $ra


get_rand_int:
    # Input:  void
    # Output: $v0 => random int between 0 and 3
    addi    $sp, $sp, -4
    sw      $a1, 0($sp)

    addi    $a1, $zero, BOARD_ROW_SIZE # upper bound = 3
    addi    $v0, $zero, 42 # generate rand int
    syscall

    lw      $a1, 0($sp)
    addi    $sp, $sp, 4
    jr 	    $ra


get_element:
    # Input:  $a1 => row index
    #         $a2 => column index
    # Output: $v0 => board element address
    mul     $t0, $a1, BOARD_ROW_SIZE # index = row index * 3
    add     $t0, $t0, $a2 # index += col index

    la      $v0, board
    add     $v0, $v0, $t0
    jr      $ra


get_int:
    # Input:  $a0 => prompt
    # Output: $v0 => read integer
    li      $v0, 4
    syscall
    li      $v0, 5
    syscall
    jr      $ra


display_board:
    # Input:  void
    # Output: void, prints the board to console
    addi    $sp, $sp, -4
    sw      $v0, 0($sp)
    
    lb      $a0, line_feed
    li      $v0, 11
    syscall

    la 	    $t0, board
    li      $t1, 0
   
db_for:
    bge     $t1, BOARD_SIZE, db_end
    lb      $t2, 0($t0)
    beq     $t2, PLAYER1, db_play1
    beq     $t2, PLAYER2, db_play2

    lb      $a0, underscore
    j       db_check_newline

db_play1:
    beq     $s1, PLAYER1, db_X
    j       db_O

db_play2:
    beq     $s1, PLAYER1, db_O
    j       db_X

db_X:
    lb      $a0, X
    j       db_check_newline

db_O:
    lb      $a0, O

db_check_newline:
    li      $v0, 11
    syscall

    lb      $a0, space
    li      $v0, 11
    syscall

    add     $t3, $t1, 1
    rem     $t3, $t3, BOARD_ROW_SIZE
    # Print line feed every row, when ($t1 + 1) mod 3 == 0
    bne     $t3, 0, db_for_next

    lb      $a0, line_feed
    li      $v0, 11
    syscall
    j       db_for_next

db_for_next:
    addi    $t1, $t1, 1
    addi    $t0, $t0, 1
    j       db_for

db_end:
    lw      $v0, 0($sp)
    addi    $sp, $sp, 4
    jr      $ra


get_game_state:
    # Input:  void
    # Output: 0 => game is still going and no winner
    #         1 => player1 won
    #         2 => player2 won
    #         3 => draw.
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    li      $t0, 0 # index 1
    li      $t1, 0 # index 2
    li      $t2, 0 # row player1
    li      $t3, 0 # row player2
    li      $t4, 0 # column player 1
    li      $t5, 0 # column player 2

ggs_outer_for:
    beq     $t2, 3, ggs_return_play1
    beq     $t4, 3, ggs_return_play1
    beq     $t3, 3, ggs_return_play2
    beq     $t5, 3, ggs_return_play2

    li      $t2, 0
    li      $t3, 0
    li      $t4, 0
    li      $t5, 0

    bge     $t0, BOARD_ROW_SIZE, ggs_check_ldiag
    li      $t1, 0

ggs_inner_for:
    la      $t6, board
    mul     $t7, $t0, BOARD_ROW_SIZE
    add     $t7, $t7, $t1

    add     $t6, $t6, $t7
    lb      $t7, 0($t6)

    beq     $t7, PLAYER1, if_i_play1_row
    beq     $t7, PLAYER2, if_i_play2_row
    j       if_check_col

if_i_play1_row:
    addi    $t2, $t2, 1
    j       if_check_col

if_i_play2_row:
    addi    $t3, $t3, 1

if_check_col:
    la      $t6, board
    mul     $t7, $t1, BOARD_ROW_SIZE
    add     $t7, $t7, $t0

    add     $t6, $t6, $t7
    lb      $t7, 0($t6)

    beq     $t7, PLAYER1, if_i_play1_col
    beq     $t7, PLAYER2, if_i_play2_col
    j       if_check_cont

if_i_play1_col:
    addi    $t4, $t4, 1
    j       if_check_cont

if_i_play2_col:
    addi    $t5, $t5, 1

if_check_cont:
    addi    $t1, $t1, 1
    blt     $t1, BOARD_ROW_SIZE, ggs_inner_for
    addi    $t0, $t0, 1
    j       ggs_outer_for

ggs_check_ldiag:
    la      $t0, board
    lb      $t1, 0($t0)
    lb      $t2, 4($t0)
    lb      $t3, 8($t0)

    beq     $t1, $t2, cd_check_lmid

ggs_check_rdiag:
    lb      $t1, 2($t0)
    lb      $t2, 4($t0)
    lb      $t3, 6($t0)

    beq     $t1, $t2, cd_check_rmid
    j       ggs_check_full

cd_check_lmid:
    beq     $t2, $t3, cd_check_last
    j       ggs_check_rdiag

cd_check_rmid: 
    beq     $t2, $t3, cd_check_last
    j       ggs_check_full

cd_check_last:
    beq     $t1, PLAYER1, ggs_return_play1
    beq     $t1, PLAYER2, ggs_return_play2

ggs_check_full:
    li      $t1, 0

cf_for:
    bge     $t1, BOARD_SIZE, ggs_return_full
    lb     	$t2, 0($t0)
    beq     $t2, EMPTY, ggs_return_empty
    addi    $t0, $t0, 1
    addi    $t1, $t1, 1
    j       cf_for

ggs_return_full:
    li      $v0, 3
    j       ggs_return

ggs_return_empty:
    li      $v0, 0
    j       ggs_return

ggs_return_play1:
    li      $v0, 1
    j       ggs_return

ggs_return_play2:
    li      $v0, 2

ggs_return:
    lw      $ra, 0($sp)
    addi    $sp, $sp, 4
    jr      $ra
