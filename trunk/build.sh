#!/bin/sh

as -o bootcd.o bootcd.s
ld -N -Ttext 0x7c00 -S --oformat binary -o bootcd.bin bootcd.o

gcc -ffreestanding -nostdlib -nostartfiles -nodefaultlibs -nostdinc \
    -Os -ansi -pedantic -W -Wall -S -o kernel.s kernel.c
as -o lv0.o x86-64.s kernel.s
ld -N -Ttext 0x8000 -S --oformat binary -o lv0.bin lv0.o

mkdir iso/
cp bootcd.bin iso/
cp lv0.bin iso/
mkisofs -R -no-emul-boot -iso-level 4 -boot-load-size 4 -b bootcd.bin -c boot.catalog -A lv0 -o lv0.iso iso/ 

rm -rf bootcd.o kernel.s lv0.o bootcd.bin lv0.bin iso/

qemu-system-x86_64 -serial stdio -boot d -cdrom lv0.iso 
