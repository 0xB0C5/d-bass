@echo off
if not exist build mkdir build
ca65 src/main.asm -o build/main.o --debug-info
ld65 build/main.o -C dmc.cfg -o build/dmc.nes --dbgfile build/dmc.dbg
