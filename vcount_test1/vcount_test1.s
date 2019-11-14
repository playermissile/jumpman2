        *= $2860

; os memory map
color0 = $2c4
color1 = $2c5
color2 = $2c6
color3 = $2c7
color4 = $2c8
colpf0 = $d016
colpf1 = $d017
colpf2 = $d018
colpf3 = $d019
colbak = $d01a
random = $d20a
wsync = $d40a
vcount = $d40b

; jumpman level storage
ls_coin_remain = $283e
ls_jmp_out_of_lives = $283f
ls_out_of_lives_ptr = $2840
ls_level_complete_ptr = $2844


; jumpman memory map
p2state = $3058
p2datal = $305d
p2datah = $3062
p2height = $3067
p2x = $306c
p2y = $3071
p2num = $3076


m0state = $30a2
m0x = $30a6
m0y = $30aa
jmalive = $30bd
jmstatus = $30be
lives_left = $30f0
getq2 = $41e0
bangsnd = $4974

; my vars
centerx = $80
centery = $70
gunstepinit = 6
mindelay = 3 * gunstepinit
gundata = $2e00

gameloop
        jsr $49d0
?gl1    jsr $4b00
        lda ls_coin_remain
        cmp #$00
        beq ?glexit
        lda vcount
        sta wsync
        cmp #30
        bcc ?gldead
        cmp #80
        bcc ?gl1a
        lda color0
?gl1a   sta colpf0
?gldead lda jmstatus
?gl2    cmp #$08
        bcc ?gl1
        lda lives_left
        cmp #$ff
        bne gameloop
        jmp ls_jmp_out_of_lives
?glexit jmp (ls_level_complete_ptr)
