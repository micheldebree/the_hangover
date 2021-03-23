; .const KOALA_TEMPLATE = "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
; .var picture = LoadBinary("arnie.kla", KOALA_TEMPLATE)
; .var music = LoadSid("terminator.sid")

!include "lib/macros.asm"
!use "lib/sid" as sid
!use "lib/koala" as koala
!use "lib/spritepad" as spritepad
!use "lib/bytes" as bytes
!use "lib/debug" as debug
!use "lib/sines" as sines

!let music = sid("lastnight1c.sid")
!let pic = koala("hangover.kla")
!let spritesTitle = spritepad.loadV1("titles.spd")

!let vicBase = $4000

!let titleY = [100, 100+24, 220] ; y locations for title lines
!let lineColors = [$01, $01, $01] ; sprite colors per line
!let sineMask = %01111111

!let zp = { ; zero page adresses to use as local variables
  a: $fa
}
!let sineIndex = [$fb, $fc, $fd]

!macro graphicPointers(bitmap, screenMem) {
  ; bitmap: $0000 or $2000 (relative to vic bank)
  ; screenmem: $0000 to $3fff, steps of $0400
  !let screenMemP = (Math.floor(screenMem / $0400) & %1111)
  !let bitmapP = (Math.floor(bitmap / $2000) & 1)

  lda #(screenMemP << 4 | bitmapP << 3)
  sta $d018
}

!macro logRange(label, from) {
  !! debug.log(label, ": ", bytes.hex(from), "-", bytes.hex(*))
}

!macro setupSprites(lineNr) {
  lda #titleY[lineNr] - 4
wait:
  cmp $d012
  bne wait

  inc $d020
  ldy #titleY[lineNr]
  ldx #lineColors[lineNr]
  !for i in range(8) {
    lda #spritesTitleData / 64 + lineNr * 8 + i
    sta screenRam + $03f8 + i
    sty $d001 + 2 *i
    stx $d027 + i
  }
  ldx #0
  ldy #0
  lda spriteD010
  sta $d010
set_x:  
  lda spriteX,x
  sta $d000,y
  iny
  iny
  inx
  cpx #8
  bne set_x

  dec $d020
}

* = $0801

+basicStart(start)

start:
        sei             ; Turn off interrupts
        jsr $ff81       ; ROM Kernal function to clear the screen
        lda #%00110101
        sta $01         ; Turn off Kernal ROM

        lda #$7f
        sta $dc0d      ; no timer IRQs
        lda $dc0d      ; acknowledge CIA interrupts

        lda #<nmi
        sta $fffa
        lda #>nmi
        sta $fffb      ; dummy NMI (Non Maskable Interupt) to avoid crashing due to RESTORE

        +selectVicBank(vicBase / $4000)
        +graphicPointers(bitmap - vicBase, screenRam - vicBase)

        lda #$d8
        sta $d016
        lda #$3b
        sta $d011
        lda #0
        sta $d020
        jsr music.init
        ; lda pic.backgroundColor
        lda #0
        sta $d021
        ldx #0
loop:
        !for i in range(4) { ; move color ram
          lda i * $100 + colorRam,x
          sta i * $100 + $d800,x
        }
        inx
        bne loop

; sprites

        lda #$ff
        sta $d015
        ; lda #%11100000
        ; lda #0
        ; sta $d010

        ldx #1
        !for i in range(8) { ; setup sprites
          lda #spritesTitleData / 64 + i
          lda #152-8 + (i * 24)
          sta $d000 + 2 * i
          stx $d027 + i
        }

        lda #titleY[0] - 16
        sta $d012

        lda #<irq
        sta $fffe
        lda #>irq
        sta $ffff   ; Setup the raster interrupt pointer to point to our own code.

        lda #$01
        sta $d01a   ; Enable raster interrupts and turn interrupts back on
        cli

        jmp *       ; Do nothing and let the interrupt do all the work.
irq:
        +setupSprites(0);
        +setupSprites(1);
        +setupSprites(2);
        jsr music.play

move_sprites: {
!let x_offset = zp.a

        ldx sineIndex[0]
        ldy #0
        sty x_offset
        sty spriteD010
set_sprite_x:
        lsr spriteD010
        lda sineLo,x
        clc
        adc x_offset
        sta spriteX,y
        lda sineHi,x
        adc #0
        beq no_overflow
        lda spriteD010
        ora #%10000000
        sta spriteD010
no_overflow:
        lda x_offset
        clc
        adc #24
        sta x_offset
        iny
        cpy #8
        bmi set_sprite_x

        lda sineIndex[0]
        clc
!let sine_speed = * + 1
        adc #1
        and #sineMask
        sta sineIndex[0]
        cmp #sineMask / 2
        bne done  
        ; lda #0
        ; sta sine_speed
done:
        ; lda spriteD010
        ; sta $d010
}

        asl $d019
nmi:
        rti

spriteX:
  !fill 3 * 8, 0
spriteD010:
  !fill 3, 0

+logRange("Code", start)

* = music.location
!byte music.data
+logRange("Music", music.location)

; * = $1c00 ;- $2000

!align $0100
colorRam:
!byte pic.colorRam
+logRange("Color RAM", colorRam)

!align $0100
!let sine = sines.sine01(341, 200, sineMask + 1)
sineLo: 
  !byte bytes.loBytes(sine)
sineHi:
  !byte bytes.hiBytes(sine)
+logRange("Sine", sineLo)

* = vicBase 

bitmap:
!byte pic.bitmap
+logRange("Bitmap", bitmap)

!align $0400
screenRam:
!byte pic.screenRam
+logRange("Screen RAM", screenRam)

!align 64
spritesTitleData:
!byte spritesTitle.data

+logRange("Sprites", spritesTitleData)
!! debug.log(($8000 - *) /64, " sprites left")
