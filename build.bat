@echo off

fasm boot\bootload.asm
fasm picodos.asm

xcopy boot\bootload.bin /Y
xcopy picodos.sys bin /Y

bfi -f=picodos.img -l=PicoDOS -b=bootload.bin bin

:Exit_OK
echo Floppy Image created successfully!
rem pause
rem exit 0