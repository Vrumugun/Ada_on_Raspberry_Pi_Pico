
# Doc

https://www.raspberrypi.com/products/raspberry-pi-pico/

https://pico-doc.synack.me/

https://github.com/JeremyGrosser/pico_examples

# Create project

alr init --bin time_triggered_system_1

cd time_triggered_system_1

alr with pico_bsp

alr build

# Program with picotool

- ../picotool/picotool.exe uf2 convert bin/time_triggered_system_1 -t elf bin/time_triggered_system_1.uf2
- ../picotool/picotool.exe load bin/time_triggered_system_1.uf2

# USB serial

The application will print a header message at startup and a heartbeat message every 10 seconds.
