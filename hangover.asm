!let startline = $32      ; raster interrupt occurs at this rasterline
; .const KOALA_TEMPLATE = "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
; .var picture = LoadBinary("arnie.kla", KOALA_TEMPLATE)
; .var music = LoadSid("terminator.sid")

!include "lib/macros.asm"
!use "lib/sid" as sid
!use "lib/koala" as koala
!use "lib/spd" as spd
!use "lib/bytes" as bytes
!use "lib/debug" as debug

!let music = sid("hangover.sid")
!let pic = koala("hangover.kla")
!let sprites = spd("mysprites.spd")

!let vicBase = $4000
; !let vicBank = Math.floor(vicBase / $4000)


!macro vicBank(bank) {
  ; 0 = $0000-$3fff
  ; 1 = $4000-$7fff (no rom chars)
  ; 2 = $8000-$bfff
  ; 3 = $c000=$ffff
  lda $dd00
  and #%11111100
  ora #(bank ^ %11)
  sta $dd00
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


; bitmap: $4000-$6000
; screenRam: $6000-

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

        +vicBank(1)
        +graphicPointers(bitmap-vicBase, screenRam-vicBase)

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
        !for i in range(4) {
          lda i * $100 + colorRam,x
          sta i * $100 + $d800,x
        }
        inx
        bne loop

; sprites

        lda #$ff
        sta $d015
        lda #%11100000
        sta $d010
        !for i in range(8) {
          lda #spriteData/64 + i
          sta screenRam + $03f8 + i
          lda #152-8 + (i * 24)
          sta $d000 + 2 * i
          lda #190
          sta $d001 + 2 * i
          lda #1
          sta $d027 + i
        }

 ; configure the rasterline at which the raster interrupt request should occur
        lda #startline
        sta $d012       ; set the lowest 8 bits of the irq rasterline

        lda #<irq
        sta $fffe
        lda #>irq
        sta $ffff   ; Setup the raster interrupt pointer to point to our own code.

        lda #$01
        sta $d01a   ; Enable raster interrupts and turn interrupts back on
        cli

        jmp *       ; Do nothing and let the interrupt do all the work.

irq:
        lda #$ff
        sta $d019 ; acknowledge interrupt
        jsr music.play
nmi:
        rti

+logRange("Code", start)

* = music.location
!byte music.data
+logRange("Music", music.location)

; * = $1c00 ;- $2000

colorRam:
!byte pic.colorRam
+logRange("Color RAM", colorRam)


* = vicBase 
bitmap:
!byte pic.bitmap
+logRange("Bitmap", bitmap)

!align $0400
screenRam:
!byte pic.screenRam
+logRange("Screen RAM", screenRam)

!align 64
spriteData:
!for i in range(sprites.numSprites) {
  !byte sprites.data[i]
}
+logRange("Sprites", spriteData)
!! debug.log(($8000 - *) /64, " sprites left")
