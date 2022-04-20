#!/bin/bash

BASE=$(readlink -f _mtd7.extracted)
MAX_SIZE=83886080

mkdir -p build
cd build
rm *

touch mtd7_new

mksquashfs $BASE/40 m40.squashfs -comp xz -b 131072 -no-xattrs -all-root -progress -always-use-fragments -no-exports -noappend
mkimage -O Linux -A ARM -T ramdisk -C none -n 'uboot initramfs rootfs' -d m40.squashfs startpart

cat startpart >> mtd7_new

SIZE=$(expr 41943040 - $(wc -c startpart | cut -d ' ' -f 1))
echo $SIZE

truncate -s +$SIZE mtd7_new

mksquashfs $BASE/2800040 m2800040.squashfs -comp xz -b 131072 -no-xattrs -all-root -progress -always-use-fragments -no-exports -noappend
mkimage -O Linux -A ARM -T ramdisk -C none -n 'uboot initramfs rootfs' -d m2800040.squashfs endpart

cat endpart >> mtd7_new

truncate -s +$(expr $MAX_SIZE - $(wc -c mtd7_new | cut -d ' ' -f 1)) mtd7_new

mv mtd7_new ..
