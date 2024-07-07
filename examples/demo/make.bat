@echo off
if not exist build mkdir build

ca65 src/main.asm -o build/main.o --debug-info
ca65 ../../d-bass.asm -o build/dbass.o --debug-info

ld65 build/main.o build/dbass.o -C d-bass-demo.cfg -o build/d-bass-demo.nes --dbgfile build/d-bass-demo.dbg
