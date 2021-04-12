.PHONY: %.debug clean
.PRECIOUS: %.exe.prg

%.debug: %.prg
	npm run debug

hangover.prg: hangover.asm titles.spd 
	npm run build

titles.spd: titles.png
	npm run build_resources

