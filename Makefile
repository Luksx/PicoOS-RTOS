# PicoOS-RTOS bare-metal build

PROJECT      := pico
BUILD_DIR    := build
TARGET       := $(BUILD_DIR)/$(PROJECT)

CC           := arm-none-eabi-gcc
OBJCOPY      := arm-none-eabi-objcopy
SIZE         := arm-none-eabi-size
OBJDUMP      := arm-none-eabi-objdump
GDB          := arm-none-eabi-gdb
OPENOCD      := openocd
PICOTOOL     := picotool

CPU          := -mcpu=cortex-m0plus -mthumb
LDSCRIPT     := rp2040.ld

SOURCES      := startup.S main.c
OBJECTS      := $(patsubst %.S,$(BUILD_DIR)/%.o,$(filter %.S,$(SOURCES))) \
                $(patsubst %.c,$(BUILD_DIR)/%.o,$(filter %.c,$(SOURCES)))
DEPFILES     := $(OBJECTS:.o=.d)

CPPFLAGS     := -I.
CFLAGS       := $(CPU) \
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

ASFLAGS      := $(CPU) \
                -ffreestanding \
                -MMD \
                -MP

LDFLAGS      := $(CPU) \
                -T $(LDSCRIPT) \
                -nostdlib \
                -nostartfiles \
                -Wl,--gc-sections \
                -Wl,--build-id=none \
                -Wl,-Map=$(TARGET).map

LDLIBS       := -lgcc

OPENOCD_CFG  := -f interface/cmsis-dap.cfg \
                -f target/rp2040.cfg

.PHONY: all
all: $(TARGET).elf $(TARGET).bin
	@$(SIZE) $(TARGET).elf

.PHONY: elf
elf: $(TARGET).elf

.PHONY: bin
bin: $(TARGET).bin

.PHONY: uf2
uf2: $(TARGET).uf2

.PHONY: check
check:
	@command -v $(CC) >/dev/null || \
		(echo "Error: $(CC) not found"; exit 1)
	@command -v $(OBJCOPY) >/dev/null || \
		(echo "Error: $(OBJCOPY) not found"; exit 1)
	@command -v $(SIZE) >/dev/null || \
		(echo "Error: $(SIZE) not found"; exit 1)
	@echo "Toolchain found."

$(TARGET).elf: $(OBJECTS) $(LDSCRIPT)
	@mkdir -p $(dir $@)
	@echo "LD      $@"
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS) $(LDLIBS)

$(TARGET).bin: $(TARGET).elf
	@echo "OBJCOPY $@"
	$(OBJCOPY) -O binary $< $@

$(TARGET).uf2: $(TARGET).elf
	@echo "UF2     $@"
	$(PICOTOOL) uf2 convert $< $@

$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(dir $@)
	@echo "AS      $@"
	$(CC) $(ASFLAGS) $(CPPFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "CC      $@"
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

.PHONY: flash
flash: $(TARGET).elf
	$(OPENOCD) $(OPENOCD_CFG) \
		-c "program $(TARGET).elf verify reset exit"

.PHONY: debug
debug: $(TARGET).elf
	@set -e; \
	$(OPENOCD) $(OPENOCD_CFG) > $(BUILD_DIR)/openocd.log 2>&1 & \
	OPENOCD_PID=$$!; \
	trap 'kill $$OPENOCD_PID 2>/dev/null || true' EXIT INT TERM; \
	sleep 2; \
	$(GDB) $(TARGET).elf \
		-ex "target extended-remote :3333" \
		-ex "monitor reset halt" \
		-ex "break Reset_Handler" \
		-ex "continue"

.PHONY: disassemble
disassemble: $(TARGET).elf
	$(OBJDUMP) -d -S $(TARGET).elf

.PHONY: symbols
symbols: $(TARGET).elf
	$(OBJDUMP) -t $(TARGET).elf

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

.PHONY: rebuild
rebuild: clean all

-include $(DEPFILES)