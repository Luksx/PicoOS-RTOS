cmake_minimum_required(VERSION 3.16)
project(rp2040_boot2 LANGUAGES C ASM)

if(NOT DEFINED PICO_SDK_PATH OR PICO_SDK_PATH STREQUAL "")
    message(FATAL_ERROR "PICO_SDK_PATH is required (for example: -DPICO_SDK_PATH=$ENV{HOME}/pico-sdk).")
endif()

set(BOOT2_SRC "${PICO_SDK_PATH}/src/rp2040/boot_stage2/boot2_w25q080.S")
set(BOOT2_LD "${PICO_SDK_PATH}/src/rp2040/boot_stage2/boot_stage2.ld")
set(BOOT2_PAD "${PICO_SDK_PATH}/src/rp2040/boot_stage2/pad_checksum")

foreach(path IN ITEMS "${BOOT2_SRC}" "${BOOT2_LD}" "${BOOT2_PAD}")
    if(NOT EXISTS "${path}")
        message(FATAL_ERROR "Required Pico SDK file is missing: ${path}")
    endif()
endforeach()

find_package(Python3 REQUIRED COMPONENTS Interpreter)

add_executable(boot2_raw_elf "${BOOT2_SRC}")
target_include_directories(boot2_raw_elf PRIVATE
    "${PICO_SDK_PATH}/src/common/pico_base_headers/include"
    "${PICO_SDK_PATH}/src/rp2040/hardware_regs/include"
    "${PICO_SDK_PATH}/src/rp2040/boot_stage2/asminclude"
)
target_link_options(boot2_raw_elf PRIVATE
    -nostdlib
    -nostartfiles
    "-Wl,--script=${BOOT2_LD}"
    -Wl,--build-id=none
)

set(BOOT2_RAW_BIN "${CMAKE_CURRENT_BINARY_DIR}/boot2_raw.bin")
set(BOOT2_PADDED_S "${CMAKE_CURRENT_BINARY_DIR}/boot2_padded.S")
set(BOOT2_OBJECT "${CMAKE_CURRENT_BINARY_DIR}/boot2_padded.o")
set(BOOT2_BIN "${CMAKE_CURRENT_BINARY_DIR}/boot2.bin")

add_custom_command(
    OUTPUT "${BOOT2_RAW_BIN}"
    COMMAND "${CMAKE_OBJCOPY}" -Obinary "$<TARGET_FILE:boot2_raw_elf>" "${BOOT2_RAW_BIN}"
    DEPENDS boot2_raw_elf
    VERBATIM
)

add_custom_command(
    OUTPUT "${BOOT2_PADDED_S}"
    COMMAND "${Python3_EXECUTABLE}" "${BOOT2_PAD}" -s 0xffffffff "${BOOT2_RAW_BIN}" "${BOOT2_PADDED_S}"
    DEPENDS "${BOOT2_RAW_BIN}" "${BOOT2_PAD}"
    VERBATIM
)

add_custom_command(
    OUTPUT "${BOOT2_OBJECT}"
    COMMAND "${CMAKE_ASM_COMPILER}" -c "${BOOT2_PADDED_S}" -o "${BOOT2_OBJECT}"
    DEPENDS "${BOOT2_PADDED_S}"
    VERBATIM
)

add_custom_command(
    OUTPUT "${BOOT2_BIN}"
    COMMAND "${CMAKE_OBJCOPY}" -Obinary "${BOOT2_OBJECT}" "${BOOT2_BIN}"
    DEPENDS "${BOOT2_OBJECT}"
    VERBATIM
)

add_custom_target(boot2_bin ALL DEPENDS "${BOOT2_BIN}")
