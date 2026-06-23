ifndef VERSION
    $(error The 'VERSION' argument is required (pal, ntsc_u, ntsc_j). Usage: make VERSION=pal)
endif

# Target naming matching your yaml configuration
TARGET    = goldeneye
BUILD_DIR = build
SPLAT_DIR = splat.$(VERSION)
ROM       = $(BUILD_DIR)/$(TARGET).$(VERSION).z64
ELF       = $(BUILD_DIR)/$(TARGET).$(VERSION).elf
LD_SCRIPT = $(SPLAT_DIR)/goldeneye.ld

# Toolchain Definitions
CC        = $(IDO_53_DIR)/cc
AS        = mips-linux-gnu-as
LD        = mips-linux-gnu-ld
OBJCOPY   = mips-linux-gnu-objcopy

# Compiler/Assembler flags
CFLAGS    = -Wab,-r4300_mul -non_shared -G 0 -Xcpluscomm -O2
ASFLAGS   = -march=mips4 -mabi=32 -I $(SPLAT_DIR)/include

# Object lists mapping to where the splat linker expects them
OBJS = \
    $(BUILD_DIR)/$(VERSION)/asm/header.s.o \
    $(BUILD_DIR)/$(VERSION)/assets/boot.bin.o \
    $(BUILD_DIR)/$(VERSION)/asm/entry.s.o \
    $(BUILD_DIR)/$(VERSION)/asm/game_code.s.o \
    $(BUILD_DIR)/$(VERSION)/assets/assets.bin.o

all: $(ROM)
	@md5sum -c goldeneye.$(VERSION).md5 && echo "ROM MATCHES!" || (echo "ROM MISMATCH!"; exit 1)

# Rule 1: Assemble MIPS files
$(BUILD_DIR)/$(VERSION)/asm/%.s.o: $(SPLAT_DIR)/asm/%.s
	@mkdir -p $(shell dirname $@)
	$(AS) $(ASFLAGS) $< -o $@

# Rule 2: Package asset blobs
$(BUILD_DIR)/$(VERSION)/assets/%.bin.o: $(SPLAT_DIR)/assets/%.bin
	@mkdir -p $(shell dirname $@)
	$(OBJCOPY) -I binary -O elf32-tradbigmips -B mips $< $@

# Rule 3: Link everything together using your splat linker script
$(ELF): $(OBJS)
	$(LD) -T $(LD_SCRIPT) -Map $(BUILD_DIR)/$(TARGET).$(VERSION).map -o $@

# Rule 4: Strip ELF headers to create final raw N64 ROM
$(ROM): $(ELF)
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
