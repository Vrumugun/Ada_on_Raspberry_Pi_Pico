
# Doc

https://www.raspberrypi.com/products/raspberry-pi-pico/

https://pico-doc.synack.me/

https://github.com/JeremyGrosser/pico_examples

# Create project

alr init --bin hello_pico

cd hello_pico

alr with pico_bsp

# Program

- ../picotool/picotool.exe uf2 convert bin/usb_test2 -t elf bin/usb_test2.uf2
- ../picotool/picotool.exe load bin/usb_test2.uf2

# Debug

## SWD Debugger

https://www.youtube.com/watch?v=g3sGKoLafew

## pico-debug

https://github.com/majbthrd/pico-debug/

## picotool

https://github.com/raspberrypi/picotool
