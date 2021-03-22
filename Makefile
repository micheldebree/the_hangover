C64JASM=npx c64jasm
VICE=x64sc
DEBUGGER=/Applications/C64\ Debugger.app/Contents/MacOS/C64\ Debugger

.PHONY: %.debug clean
.PRECIOUS: %.exe.prg

%.prg: %.asm
	$(C64JASM) "$<" --c64debugger-symbols "$*.dbg" --out "$@" --verbose

%.exe.prg: %.prg
	exomizer sfx basic "$<" -o "$@"
	$(VICE) "$@"

%.debug: %.prg
	# $(DEBUGGER) -prg "$<" -pass -autojmp -layout 9
	$(DEBUGGER) -prg "$<" -pass -unpause -wait 3000 -autojmp -layout 9
	# x64sc -initbreak ready -moncommands "$*.vs" "$@"

%.spd: %.png
	retropixels -m sprites -h --rows 1 "$<"

hangover.prg: hangover.asm \
	hangover.spd \
	credits.spd

clean:
	rm -f *.prg
	rm -f *.exe.prg
	rm -f *.sym
	rm -f *.vs
	rm -f *.dbg
	rm -f *.d64
	rm -f *.spd
