        *= $2860

; os memory map
vdslst = $200
color0 = $2c4
color1 = $2c5
color2 = $2c6
color3 = $2c7
color4 = $2c8
hposp0 = $d000
hposp1 = $d001
hposp2 = $d002
hposp3 = $d003
hposm0 = $d004
hposm1 = $d005
hposm2 = $d006
hposm3 = $d007
sizep0 = $d008
sizep1 = $d009
sizep2 = $d00a
sizep3 = $d00b
sizem0 = $d00c
colpm0 = $d012
colpm1 = $d013
colpm2 = $d014
colpm3 = $d015
colpf0 = $d016
colpf1 = $d017
colpf2 = $d018
colpf3 = $d019 ; also color of 5th player
colbak = $d01a
prior = $d01b
random = $d20a
wsync = $d40a
vcount = $d40b

; jumpman level storage
ls_player2_color = $282c
ls_player3_color = $282d
ls_coin_remain = $283e
ls_jmp_out_of_lives = $283f
ls_out_of_lives_ptr = $2840
ls_level_complete_ptr = $2844


; jumpman memory map

jm_pmbase = $6000
jm_pmbase_m = $6300
jm_pmbase_p0 = $6400
jm_pmbase_p1 = $6500
jm_pmbase_p2 = $6600
jm_pmbase_p3 = $6700

; scratch

src = $b4
index1 = $ce

; players 0 and 1 are reserved for jumpman and shadow, respectively

; player 2
p2active = $3058
p2datal = $305d
p2datah = $3062
p2height = $3067
p2x = $306c
p2y = $3071
p2frame = $3076

; player 3
p3active = $3059
p3datal = $305e
p3datah = $3063
p3height = $3068
p3x = $306d
p3y = $3072
p3frame = $3077

; combined missile player
p4active = $3055
p4datal = $305a
p4datah = $305f
p4height = $3064
p4x = $3069
p4y = $306e
p4frame = $3073

; collisions
jm_collide_m0pl = $3098
jm_collide_m1pl = $3099
jm_collide_m2pl = $309a
jm_collide_m3pl = $309b

; bullets
m0state = $30a2
m1state = $30a3
m2state = $30a4
m3state = $30a5
m0x = $30a6
m1x = $30a7
m2x = $30a8
m3x = $30a9
m0y = $30aa
m1y = $30ab
m2y = $30ac
m3y = $30ad

; status
jmalive = $30bd
jmstatus = $30be
lives_left = $30f0
getq2 = $41e0
bangsnd = $4974


; 180 scan lines of snow, 16 scan lines per group of 4 missiles, so there
; are 11 full groups plus a quarter group. At any one time, there are 45
; snowflakes on screen.
xpos_storage = jm_pmbase_p2
id_storage = jm_pmbase_p3

; local constants
top_vcount = 10
bot_vcount = 100
top_mmem = 20
bot_mmem = 200

; local vars
start_y = $80
next_y = $70


gameloop
        jsr $49d0
?gl1    jsr $4b00
        lda ls_coin_remain
        cmp #$00
        beq ?glexit

        ; till I find a better way to deal with the gameloop not running
        ; during the jumpman respawn sequence at $49d0, just don't run
        ; the vcount routine during that time. This causes players to be
        ; duplicated at their x pos all the way down the screen, so the
        ; vbi will set the players off screen during this time
        lda jmalive     ; Till I find a better way to 
        cmp #$02        ; dead with birdies?
        beq ?gldone


        jsr gamelogic   ; do level-specific game logic


?gldone lda jmstatus
?gl2    cmp #$08
        bcc ?gl1
        lda lives_left
        cmp #$ff
        bne gameloop
        jmp ls_jmp_out_of_lives
?glexit jmp (ls_level_complete_ptr)


; level logic goes here. This is run between the main game screen scan lines,
; once it's outside those lines it returns to the main game loop where normal
; level processing resumes, checking for lives lost, etc.
gamelogic
        ; 1st 4 snowflakes hpos is set in VBI, that's the first 8 scan lines
        ; equiv to 4 vcount.
        lda vcount
?1      cmp vcount
        beq ?1
        cmp #top_vcount+4
        bcc ?done
        cmp #bot_vcount
        bcs ?done

        ; ok, within region that vcount is going to alter missile positions
        asl a
        tay
        lda id_storage,y
        tax
        lda xpos_storage,y
        sta hposm0,x
        jmp gamelogic
?done   rts


levelinit
        jsr dliinit
        jsr missileinit
        rts


dliinit
        rts


missileinit
        ldy #top_mmem   ; start at top of visible playfield
        sty start_y
        rts



; move snow down one line, only one quarter of snowflakes every vbi.
; after 8 times through this, there will be space to put a new snowflake
; at the top of the screen
snow_fall
        ldy start_y
?1      lda jm_pmbase_m,y
        sta jm_pmbase_m+1,y
        lda xpos_storage,y
        sta xpos_storage+1,y
        lda id_storage,y
        sta id_storage+1,y
        lda #0
        sta jm_pmbase_m,y
        tya
        clc
        adc #16
        tay
        cpy #bot_mmem
        bcc ?1

        ; reset start_y for next VBI loop to get next set of missiles
        ldy start_y
        iny
        iny
        iny
        iny
        tya
        cmp #top_mmem+16
        bcc ?2

        ; through all 4 sets of missiles, need to move one scanline down
        ; and repeat. 4 loops total to move stuff down in 4 groups
        sec
        sbc #15
        cmp #top_mmem+4
        bcc ?2
        lda #top_mmem
?2      sta start_y
        rts


; put a new snowflake at the top
new_snow
        ldy #top_mmem
        ldx next_snowflake
        lda snowflakes,x
        ;lda #$02
        sta jm_pmbase_m,y
        txa
        sta id_storage,y
        lda random
        clc
        adc snow0x,x
        sta xpos_storage,y
        inx
        txa
        and #3
        sta next_snowflake
        rts


vbi1
        lda jmalive     ; check jumpman alive state
        cmp #$02        ; dead with birdies?
        bne alive       ; nope, continue
        lda #0          ; the DLI won't run during jumpman respawn, so move
        sta hposm0      ;  the real players off screen so they won't be
        sta hposm1      ;  shown repeated at same xpos all down the screen
        sta hposm2
        sta hposm3
exit1   jmp $311b
alive   lda $2800       ; check if already initialized
        cmp #$ff        ; already initialized = $ff
        beq ?step       ; yep, move
        jsr levelinit
        lda #$ff        ; store already initialized flag
        sta $2800

?step
        jsr snow_fall

        ; only move 1/4 of missiles per VBI
        dec loop_count
        bne ?1
        lda #16
        sta loop_count
        jsr new_snow

?1      ldy #top_mmem   ; restore positions for top of next frame
?2      lda id_storage,y
        tax
        lda xpos_storage,y
        sta hposm0,x
        iny
        cpy #top_mmem+16
        bcc ?2

        jmp $311b


; replace normal vbi4 with this one that ignores missile collisions,
; since missiles are abused as snowflakes now.
vbi4
        lda $309e
        ora $309f
        and #$01
        cmp #$00
        beq ?1
        lda #$01
        sta $30bd
?1      jmp $311b


snow0x .byte $a8+4
snow1x .byte $80+4
snow2x .byte $58+4
snow3x .byte $30+4
loop_count .byte 8
next_snowflake .byte 0
snowflakes .byte $02,$08,$20,$80
