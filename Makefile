CC      = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
SIZE    = arm-none-eabi-size

CPU     = -mcpu=cortex-m0plus -mthumb
CFLAGS  = $(CPU) -Wall -Os -ffunction-sections -fdata-sections -nostdlib -nostartfiles
LDFLAGS = $(CPU) -T link.ld -Wl,--gc-sections -Wl,-Map=build/pico.map --specs=nano.specs

SRCS    = startup.S main.c
OBJS    =  startup.o main.o

TARGET  = build/pico

all: $(TARGET).elf
	$(SIZE) $(TARGET).elf

$(TARGET).elf: $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.S
	$(CC) $(CPU) -c -o $@ $<

%.o: %.c
	$(CC) $(CPU) $(CFLAGS) -c -o $@ $<

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

flash: $(TARGET).elf
	openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg \
		-c "program $(TARGET).elf verify reset exit"

debug: $(TARGET).elf
	openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg &
	sleep 2
	arm-none-eabi-gdb $(TARGET).elf -ex "target remote :3333" \
		-ex "break Reset_Handler" -ex "continue"

clean:
	rm -rf build/* *.o
uf2: $(TARGET).elf
	picotool uf2 convert $(TARGET).elf $(TARGET).uf2
	@echo "→ Přetáhni $(TARGET).uf2 na RPI-RP2 (BOOTSEL)"

.PHONY: all flash debug clean uf2