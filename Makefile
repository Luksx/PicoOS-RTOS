# PicoOS-RTOS bare-metal build

PROJECT       := pico
REPO_ROOT     := $(abspath .)
BUILD_DIR     := $(REPO_ROOT)/build
TARGET_PREFIX := $(BUILD_DIR)/$(PROJECT)

CC            := arm-none-eabi-gcc
OBJCOPY       := arm-none-eabi-objcopy
SIZE          := arm-none-eabi-size
OBJDUMP       := arm-none-eabi-objdump
READELF       := arm-none-eabi-readelf
GDB           := arm-none-eabi-gdb
OPENOCD       := openocd
PICOTOOL      := picotool
PYTHON3       := python3
CMAKE         := cmake

PICO_SDK_PATH ?= $(HOME)/pico-sdk
BOOT2_SRC     := $(PICO_SDK_PATH)/src/rp2040/boot_stage2/boot2_w25q080.S
BOOT2_CMAKE   := $(REPO_ROOT)/boot2/CMakeLists.txt
BOOT2_BUILD   := $(BUILD_DIR)/boot2
BOOT2_BIN     := $(BOOT2_BUILD)/boot2.bin
BOOT2_OBJ     := $(BOOT2_BUILD)/boot2.bin.o

CPU           := -mcpu=cortex-m0plus -mthumb
LDSCRIPT      := $(REPO_ROOT)/rp2040.ld

SOURCES       := startup.S main.c
OBJECTS       := $(patsubst %.S,$(BUILD_DIR)/%.o,$(filter %.S,$(SOURCES))) \
                 $(patsubst %.c,$(BUILD_DIR)/%.o,$(filter %.c,$(SOURCES)))
DEPFILES      := $(OBJECTS:.o=.d)

TARGET_ELF    := $(TARGET_PREFIX).elf
TARGET_BIN    := $(TARGET_PREFIX).bin
TARGET_UF2    := $(TARGET_PREFIX).uf2
TARGET_MAP    := $(TARGET_PREFIX).map

CPPFLAGS      := -I$(REPO_ROOT)
CFLAGS        := $(CPU) \
                 -std=c11 \
                 -Wall \
                 -Wextra \
                 -Werror \
                 -Os \
                 -ffreestanding \
                 -fno-builtin \
                 -ffunction-sections \
                 -fdata-sections \
                 -MMD \
                 -MP
ASFLAGS       := $(CPU) \
                 -ffreestanding \
                 -MMD \
                 -MP
LDFLAGS       := $(CPU) \
                 -T $(LDSCRIPT) \
                 -nostdlib \
                 -nostartfiles \
                 -Wl,--gc-sections \
                 -Wl,--build-id=none \
                 -Wl,-Map=$(TARGET_MAP)
LDLIBS        := -lgcc

OPENOCD_CFG   := -f interface/cmsis-dap.cfg \
                 -f target/rp2040.cfg

.PHONY: all elf bin uf2 flash debug disassemble symbols check verify-layout show-layout clean rebuild

all: $(TARGET_ELF) $(TARGET_BIN) verify-layout
	@$(SIZE) $(TARGET_ELF)

elf: $(TARGET_ELF)

bin: $(TARGET_BIN)

uf2: $(TARGET_UF2)

check:
	@command -v $(CC) >/dev/null || (echo "Error: $(CC) not found"; exit 1)
	@command -v $(OBJCOPY) >/dev/null || (echo "Error: $(OBJCOPY) not found"; exit 1)
	@command -v $(OBJDUMP) >/dev/null || (echo "Error: $(OBJDUMP) not found"; exit 1)
	@command -v $(READELF) >/dev/null || (echo "Error: $(READELF) not found"; exit 1)
	@command -v $(SIZE) >/dev/null || (echo "Error: $(SIZE) not found"; exit 1)
	@command -v $(PICOTOOL) >/dev/null || (echo "Error: $(PICOTOOL) not found"; exit 1)
	@command -v $(CMAKE) >/dev/null || (echo "Error: $(CMAKE) not found"; exit 1)
	@command -v $(PYTHON3) >/dev/null || (echo "Error: $(PYTHON3) not found"; exit 1)
	@[ -r "$(BOOT2_SRC)" ] || (echo "Error: BOOT2 source not found: $(BOOT2_SRC)"; exit 1)
	@echo "Toolchain and SDK boot2 source found."

$(BOOT2_BIN): $(BOOT2_CMAKE) $(BOOT2_SRC)
	@mkdir -p $(BOOT2_BUILD)
	@echo "CMAKE   $(BOOT2_BUILD)"
	$(CMAKE) -S $(REPO_ROOT)/boot2 -B $(BOOT2_BUILD) \
		-DPICO_SDK_PATH="$(PICO_SDK_PATH)" \
		-DCMAKE_C_COMPILER="$(CC)" \
		-DCMAKE_ASM_COMPILER="$(CC)" \
		-DCMAKE_OBJCOPY="$(OBJCOPY)" \
		-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
	@echo "BUILD   $@"
	$(CMAKE) --build $(BOOT2_BUILD) --target boot2_bin
	@boot2_size="$$(wc -c < "$@")"; \
	if [ "$$boot2_size" -ne 256 ]; then \
		echo "Error: generated boot2 size is $$boot2_size bytes (expected 256)."; \
		exit 1; \
	fi

$(BOOT2_OBJ): $(BOOT2_BIN)
	@echo "OBJCOPY $@"
	$(OBJCOPY) -I binary -O elf32-littlearm -B arm \
		--rename-section .data=.boot2,alloc,load,readonly,data,contents \
		$< $@

$(TARGET_ELF): $(OBJECTS) $(BOOT2_OBJ) $(LDSCRIPT)
	@mkdir -p $(dir $@)
	@echo "LD      $@"
	$(CC) $(LDFLAGS) -o $@ $(BOOT2_OBJ) $(OBJECTS) $(LDLIBS)

$(TARGET_BIN): $(TARGET_ELF)
	@echo "OBJCOPY $@"
	$(OBJCOPY) -O binary $< $@

$(TARGET_UF2): $(TARGET_BIN)
	@echo "UF2     $@"
	$(PICOTOOL) uf2 convert $< $@ --family rp2040 --offset 0x10000000

$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(dir $@)
	@echo "AS      $@"
	$(CC) $(ASFLAGS) $(CPPFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "CC      $@"
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

show-layout: $(TARGET_ELF)
	@echo "--- Section layout (.boot2/.text) ---"
	@$(OBJDUMP) -h $(TARGET_ELF) | awk '$$2==".boot2" || $$2==".text"'
	@echo "--- Key symbols ---"
	@$(OBJDUMP) -t $(TARGET_ELF) | grep -E "(_vectors|Reset_Handler|main)$$" || true

verify-layout: $(TARGET_ELF) $(TARGET_BIN) $(BOOT2_BIN)
	@$(OBJDUMP) -h $(TARGET_ELF) | awk '\
		BEGIN { boot2_ok=0; text_ok=0; } \
		$$2==".boot2" { if ($$3=="00000100" && $$4=="10000000") boot2_ok=1; } \
		$$2==".text"  { if ($$4=="10000100") text_ok=1; } \
		END { \
			if (!boot2_ok) { print "Error: .boot2 must be at 0x10000000 with size 0x100."; exit 1; } \
			if (!text_ok)  { print "Error: .text must start at 0x10000100."; exit 1; } \
		}'
	@cmp -n 256 $(BOOT2_BIN) $(TARGET_BIN) >/dev/null || \
		(echo "Error: application binary does not begin with generated boot2 image."; exit 1)
	@echo "Layout verified: .boot2/.text addresses and boot2 binary prefix are correct."

flash: $(TARGET_ELF)
	$(OPENOCD) $(OPENOCD_CFG) \
		-c "program $(TARGET_ELF) verify reset exit"

debug: $(TARGET_ELF)
	@set -e; \
	$(OPENOCD) $(OPENOCD_CFG) > $(BUILD_DIR)/openocd.log 2>&1 & \
	OPENOCD_PID=$$!; \
	trap 'kill $$OPENOCD_PID 2>/dev/null || true' EXIT INT TERM; \
	sleep 2; \
	$(GDB) $(TARGET_ELF) \
		-ex "target extended-remote :3333" \
		-ex "monitor reset halt" \
		-ex "break Reset_Handler" \
		-ex "continue"

disassemble: $(TARGET_ELF)
	$(OBJDUMP) -d -S $(TARGET_ELF)

symbols: $(TARGET_ELF)
	$(OBJDUMP) -t $(TARGET_ELF)

clean:
	rm -rf $(BUILD_DIR)

rebuild: clean all

-include $(DEPFILES)