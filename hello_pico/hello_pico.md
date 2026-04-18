
# Doc

https://www.raspberrypi.com/products/raspberry-pi-pico/

https://pico-doc.synack.me/

https://github.com/JeremyGrosser/pico_examples

# Create project

$env:Path += ";C:\Program Files\Alire\bin"

$env:PICO_SDK_PATH += "C:\GitHub\pico-sdk"

$env:Path += ";C:\Dev\arm-gnu-toolchain-15.2.rel1-mingw-w64-i686-arm-none-eabi\bin"

alr init --bin hello_pico

cd hello_pico

alr with pico_bsp

# Program with picotool

https://github.com/raspberrypi/picotool

- ../picotool/picotool.exe uf2 convert bin/hello_pico -t elf bin/hello_pico.uf2
- ../picotool/picotool.exe load bin/hello_pico.uf2

# Debug

## pico-debug

https://github.com/majbthrd/pico-debug/

- Install Cortex-Debug extension
- Download ARM GNU toolchain (https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
- Download OpenOCD (https://openocd.org/, https://github.com/xpack-dev-tools/openocd-xpack/releases)
- Add to path
- Clone pico-sdk (https://github.com/raspberrypi/pico-sdk)
- Boot pico with BOOTSEL pressed.
- Load pico-debug: picotool/picotool.exe load -x .\pico-debug-gimmecache.uf2

## SWD Debugger

https://www.youtube.com/watch?v=g3sGKoLafew
