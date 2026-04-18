# Time triggered system - Example 2

Based on the book "The Engineering of Reliable Embedded Systems" by Michael J. Pont.

- This example implements a simple scheduler with a cycle time of 1ms.
- The following tasks are implemented:
  - Read and filter digital input, 1ms cylce time
  - Output and verify digital output, 10ms cycle time
  - Debug communication task over USB serial with 2ms cycle time.
  - Heartbeat task with 1s cycle time
  - Watchdog task with 1.1s cycle time

## Doc

https://www.raspberrypi.com/products/raspberry-pi-pico/

https://pico-doc.synack.me/

https://github.com/JeremyGrosser/pico_examples

## Create project

alr init --bin time_triggered_system_1

cd time_triggered_system_1

alr with pico_bsp

alr build

## Program with picotool

- ../picotool/picotool.exe uf2 convert bin/time_triggered_system_2 -t elf bin/time_triggered_system_2.uf2
- ../picotool/picotool.exe load bin/time_triggered_system_2.uf2

## USB serial

The application will print a header message at startup and a heartbeat message every 10 seconds.
