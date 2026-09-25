# PicoOS-RTOS (RP2040 bare-metal)

This project builds a bare-metal RP2040 firmware from `startup.S` + `main.c` and embeds an SDK-generated RP2040 `boot2.bin` at the beginning of flash.

## Prerequisites

- `arm-none-eabi-gcc` toolchain (`arm-none-eabi-gcc`, `objcopy`, `objdump`, `readelf`, `size`)
- `cmake`
- `python3`
- `picotool`
- Pico SDK checkout (default path):
  - `PICO_SDK_PATH ?= $(HOME)/pico-sdk`

If your SDK is elsewhere:

```bash
make PICO_SDK_PATH=/absolute/path/to/pico-sdk
```

## Build

```bash
make clean && make
```

What happens:
- `boot2_w25q080.S` is compiled from `${PICO_SDK_PATH}/src/rp2040/boot_stage2/boot2_w25q080.S`
- SDK `pad_checksum` is used to generate a valid RP2040 second-stage boot block
- build fails if generated `boot2.bin` is not exactly 256 bytes
- firmware links `boot2.bin` into `.boot2` and app code into `.text`

Generated outputs:
- `build/pico.elf`
- `build/pico.bin`
- `build/pico.uf2` (when running `make uf2`)
- `build/pico.map`

## Useful targets

- `make all` - build ELF + BIN and validate layout
- `make elf`
- `make bin`
- `make uf2`
- `make check` - verify required tools + SDK boot2 source
- `make show-layout` - print `.boot2`/`.text` section info
- `make verify-layout` - enforce section addresses/sizes and BIN boot2 prefix
- `make disassemble`
- `make symbols`
- `make flash`
- `make debug`
- `make clean`
- `make rebuild`

## Memory layout

- `.boot2` at `0x10000000`, size `0x100` (256 bytes)
- application `.text` (vector table + code) starts at `0x10000100`
- `.data` loads from flash and runs in RAM
- `.bss` runs in RAM

The linker script (`rp2040.ld`) includes `ASSERT` checks so invalid boot2/app placement fails the link.

## UF2 and BOOTSEL flashing

Build UF2:

```bash
make uf2
```

Flash steps:
1. Hold **BOOTSEL** while connecting the Pico over USB.
2. The board mounts as a mass-storage drive.
3. Copy `build/pico.uf2` to the drive.
