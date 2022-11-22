.data
    prompt_mode:    .asciiz "Play vs. 1=CPU or 2=User: "
    prompt_row:     .asciiz "Row (1-3): "
    prompt_col:     .asciiz "Col (1-3): "
    prompt_redo:    .asciiz "WARNING: Square not empty\n"
    underscore:     .asciiz "_"
    space: 	        .asciiz " "
    newline:        .asciiz "\n"
    player1:        .byte 1
    player2:        .byte 2
    board:          .byte 0, 0, 0, 0, 0, 0, 0, 0, 0

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
    jal     fun_display_board

    play_game:
        user1_move:
            jal     fun_get_user_input
            la      $t0, player1
            lb      $t0, 0($t0)
            sb      $t0, 0($a3) # fill square

            jal     fun_display_board

            # TODO CHECK IF GAME DONE !!!!!!!!!!!!
            bne     $s1, $zero, finish_game # game is done
            beq     $s0, 1, cpu_move
            j       user2_move
        
        user2_move:
            jal     fun_get_user_input
            la      $t0, player2
            lb      $t0, 0($t0)
            sb      $t0, 0($a3) # fill square

            jal     fun_display_board

            # TODO CHECK IF GAME DONE !!!!!!!!!!!!
            bne     $s1, $zero, finish_game # game is done
            j       user1_move

        cpu_move:
            # TODO GENERATE CPU MOVE


    finish_game:
        # TODO PRINT GAME RESULT

    j fun_init # restart game?
    #la	$v0, 10
    #syscall



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
        lb      $t0, 0($a3) # $t0 = current element
        bne     $t0, $zero, warn_user # square is filled

        lw      $ra, 0($sp)
        addi    $sp, $sp, 4
        jr      $ra

    warn_user:
        la      $a0, prompt_redo
        li      $v0, 4
        syscall
        j       get_row



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



get_element:
        mul     $t0, $a1, 3 # index = row index * 3
        add     $t0, $t0, $a2 # index += col index

        la      $a3, board
        add     $a3, $a3, $t0
        jr      $ra



get_int:    # $a0 is the prompt, $v0 is the read integer.
    li      $v0, 4
    syscall
    li      $v0, 5
    syscall
    jr      $ra



fun_display_board:
    addi    $sp, $sp, -4
    sw      $ra, 0($sp)

    la      $t0, board # board address
    li      $t1, 0 # curr index

    loop_board:
        addi    $t0, $t0, 1
        lb      $a0, 0($t0)
        li      $v0, 1
        syscall

        add     $t2, $t1, 1
        rem     $t2, $t2, 3

        bne     $t2, 0, skip_newline
        la      $a0, newline
        li      $v0, 4
        syscall

    skip_newline:
        addi    $t1, $t1, 1
        bge     $t1, 9, exit_loop
        j       loop_board

    exit_loop:
        lw      $ra, 0($sp)
        addi    $sp, $sp, 4
        jr      $ra