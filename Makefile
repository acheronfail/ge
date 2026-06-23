# Target naming matching your yaml configuration
TARGET    = goldeneye
BUILD_DIR = build
SPLAT_DIR = splat.pal
ROM       = $(BUILD_DIR)/$(TARGET).z64
ELF       = $(BUILD_DIR)/$(TARGET).elf
LD_SCRIPT = $(SPLAT_DIR)/goldeneye.pal.ld

# Toolchain Definitions
CC        = $(IDO_53_DIR)/cc
AS        = mips-linux-gnu-as
LD        = mips-linux-gnu-ld
OBJCOPY   = mips-linux-gnu-objcopy

# Compiler/Assembler flags
CFLAGS    = -Wab,-r4300_mul -non_shared -G 0 -Xcpluscomm -O2
ASFLAGS   = -march=r4300 -mabi=32 -I $(SPLAT_DIR)/include

# Object lists mapping to where the splat linker expects them
OBJS = \
    $(BUILD_DIR)/asm/header.s.o \
    $(BUILD_DIR)/assets/boot.bin.o \
    $(BUILD_DIR)/asm/entry.s.o \
    $(BUILD_DIR)/asm/game_code.s.o \
    $(BUILD_DIR)/assets/assets.bin.o

all: $(ROM)
	@md5sum -c goldeneye.md5 && echo "ROM MATCHES!" || echo "ROM MISMATCH!"

# Rule 1: Assemble MIPS files
$(BUILD_DIR)/asm/%.s.o: $(SPLAT_DIR)/asm/%.s
	@mkdir -p $(shell dirname $@)
	$(AS) $(ASFLAGS) $< -o $@

# Rule 2: Package asset blobs
$(BUILD_DIR)/assets/%.bin.o: $(SPLAT_DIR)/assets/%.bin
	@mkdir -p $(shell dirname $@)
	$(OBJCOPY) -I binary -O elf32-tradbigmips -B mips $< $@

# Rule 3: Link everything together using your splat linker script
$(ELF): $(OBJS)
	$(LD) -T $(LD_SCRIPT) -Map $(BUILD_DIR)/$(TARGET).map -o $@

# Rule 4: Strip ELF headers to create final raw N64 ROM
$(ROM): $(ELF)
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
