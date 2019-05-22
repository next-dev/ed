Z80ASM = sjasmplus
Z80ASMFLAGS = --msg=all --lst=ed.lst --lstlab --nologo --dirbol
OUTPUT_OPT = -D__IGNORE=

# Z80ASM = bin/snasm
# Z80ASMFLAGS = -map
# OUTPUT_OPT =

# Z80ASM = wine ~/wine32/zx/CSpect/CSpect_current/snasm.exe
# Z80ASMFLAGS = -map
# OUTPUT_OPT =

OUTPUT := ed.sna

INPUTFILES := $(wildcard src/*.s) $(wildcard data/*.*) Makefile
MAINSOURCE := src/ed.s
EXTRA_OUTPUTS := ed.sna.map ed.lst

.PHONY: build clean

build : $(OUTPUT)

clean :
	$(RM) -f $(OUTPUT) $(EXTRA_OUTPUTS)

$(OUTPUT) : $(INPUTFILES) $(MAINSOURCE)
	$(Z80ASM) $(Z80ASMFLAGS) $(MAINSOURCE) $(OUTPUT_OPT)$(OUTPUT)
