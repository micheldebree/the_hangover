!include "lib/macros.asm"
!use "lib/sid" as sid
!use "lib/koala" as koala
!use "lib/spritepad" as spritepad
!use "lib/bytes" as bytes
!use "lib/debug" as debug
!use "lib/sines" as sines

!let music = sid("lastnight1d.sid")
!let pic = koala("hangover.kla")
!let spriteFile = spritepad.loadV1("titles.spd")

!let sineMask = %01111111
!let titleY = [100, 100+24, 220] ; y locations for title lines
!let lineColors = [$01, $01, $01] ; sprite colors per line
!let initD010 = $ff
!let initX = 250

!let zp = { ; zero page adresses to use as local variables
  a: $fb,
  b: $fc
}

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
  lda #titleY[lineNr] - 5
wait:
  cmp $d012
  bne wait

  ; inc $d020
  ldy #titleY[lineNr]
  ldx #lineColors[lineNr]
  !for i in range(8) {
    lda #vicBase::spritesData / 64 + lineNr * 8 + i
    sta vicBase::screenRam + $03f8 + i
    sty $d001 + 2 *i
    stx $d027 + i
  }
  ldx #0
  ldy #0
  lda spriteD010 + lineNr
  sta $d010
set_x:  
  lda spriteX + 8 * lineNr,x
  sta $d000,y
  iny
  iny
  inx
  cpx #8
  bne set_x

  ; dec $d020
}

!macro moveSprites(lineNr) {

!let x_offset = zp.a
!let hi_bit = zp.b

        ldx sineIndex + lineNr
        ldy #0
        sty x_offset
        sty hi_bit
set_sprite_x:
        lsr hi_bit
        lda sineLo,x
        clc
        adc x_offset
        sta spriteX + 8 * lineNr,y
        lda sineHi,x
        adc #0
        beq no_overflow
        lda hi_bit
        ora #%10000000
        sta hi_bit
no_overflow:
        lda x_offset
        clc
        adc #24
        sta x_offset
        iny
        cpy #8
        bmi set_sprite_x

        lda sineIndex + lineNr
        clc
!let sine_speed = * + 1
        adc #0
        and #sineMask

        sta sineIndex + lineNr
        cmp #sineMask / 2
        bne no_stop  
        lda #0
        sta sine_speed
        sta after_delay + 1
no_stop:
        lda hi_bit
        sta spriteD010 + lineNr
        dec sineDelay + lineNr
        bne done
after_delay:        
        lda #1
        sta sine_speed
done:

}

* = $0801

+basicStart(setup)

setup: {
        sei             ; Turn off interrupts
        jsr $ff81       ; ROM Kernal function to clear the screen
        lda #%00110101
        sta $01         ; Turn off Kernal ROM

        lda #$7f
        sta $dc0d      ; no timer IRQs
        lda $dc0d      ; acknowledge CIA interrupts

        lda #<irq::nmi
        sta $fffa
        lda #>irq::nmi
        sta $fffb      ; dummy NMI (Non Maskable Interupt) to avoid crashing due to RESTORE

        +selectVicBank(vicBase / $4000)
        +graphicPointers(vicBase::bitmap - vicBase, vicBase::screenRam - vicBase)

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
        lda #initD010
        sta $d010

        ldx #1
        !for i in range(8) { ; setup sprites
          lda #initX
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
}

irq: {
        +setupSprites(0);
        +setupSprites(1);
        +setupSprites(2);
        +moveSprites(0);
        +moveSprites(1);
        +moveSprites(2);
        jsr music.play
        asl $d019
nmi:
        rti
}


spriteX:
  !fill 3 * 8, initX
spriteD010:
  !fill 3, initD010


sineIndex:
  !fill 3, 0
sineDelay:
  !byte $40+1, $40+$10, $40+$40

!let sine = sines.sine01(341, 200, sineMask + 1)

!align $0100
sineLo: 
  !byte bytes.loBytes(sine)
sineHi:
  !byte bytes.hiBytes(sine)
+logRange("Sine", sineLo)


* = music.location

!byte music.data
+logRange("Music", music.location)

!align $0100
colorRam:
!byte pic.colorRam
+logRange("Color RAM", colorRam)

* = $4000

vicBase: {

bitmap:
  !byte pic.bitmap

!align $0400
screenRam:
  !byte pic.screenRam

!align 64
spritesData:
  !byte spriteFile.data

+logRange("VIC data", spritesData)
!! debug.log(($8000 - *) /64, " sprites left")
}
