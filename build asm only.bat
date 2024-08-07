@echo off

HiveMapExport.exe "Graphics Sonic\Sonic.ini" "Graphics Sonic"

rem assemble final rom
IF EXIST s1built.bin move /Y s1built.bin s1built.prev.bin >NUL
axm68k /m /k /p /o oz+ sonic.asm, s1built.bin >errors.txt, sonic1.sym, sonic.lst
type errors.txt

IF NOT EXIST s1built.bin PAUSE & EXIT 2
ConvSym sonic1.sym sonic1.symcmp
copy /b s1built.bin+sonic1.symcmp s1built.bin /y

fixheadr.exe s1built.bin
exit 0
