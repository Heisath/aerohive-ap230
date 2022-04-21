# Tools and documentation for Aerohive AP230

This repository is a collection of tools and documentation around the Aerohive AP230 wireless access point. 

It does not detail general usage of the ap230, as there are many articles around the web already.
In short it is a currently very affordable wifi ap. For general setup check: \
https://gist.github.com/samdoran/6bb5a37c31a738450c04150046c1c039 \
https://forums.servethehome.com/index.php?threads/aerohive-extreme-networks-aps-no-controller-needed.31445/ 

More in depth information on hacking the ap230 can be found here: \
https://research.aurainfosec.io/hacking-the-hive/

## Accessing the Console port
The ap230 has a RJ45 console port which follows the RS232 protocol. Signal levels are -12V to 12V, normal polarity. 9600 baud, 8 bits, 1 stop bit, no parity. \
[Pin assignment](https://docs.aerohive.com/330000/docs/help/english/ng/Content/hardware/pin-assigment.htm):
```
---------------------------------
|              / \              |
|                               |
|                               |
|                               |
| 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 |
| N | N | R | G | G | T | N | N |
---------------------------------

N = not connected
G = gnd 
R = receive (host to ap230)
T = transmit (ap230 to host)
```
Beware the high signal level when using cheap usb converters!

## Accessing the UBoot 
To access the uboot you have to connect to the console, reboot the device and press any key when prompted.
The password for the uboot seems to be `AhNf?d@ta06` . 

Beware when changing uboot env, when I used `saveenv` it corrupted the storage and I had to recover it.

Full bootlog in [docs/u-boot.txt](docs/u-boot.txt)

## Accessing the hidden shell
To access the busybox shell use the hidden `_shell` command on the aerohive cli.
The password needed can be generated with the keygen in [tools/aerohive-keygen](tools), it requires the serial number.

## Partitions
All data is stored on internal flash memory. It is seperated into 9 partitions:
```
cat /proc/mtd
dev:    size   erasesize  name
mtd0: 00400000 00020000 "Uboot"
mtd1: 00040000 00020000 "Uboot Env"
mtd2: 00040000 00020000 "nvram"
mtd3: 00060000 00020000 "Boot Info"
mtd4: 00060000 00020000 "Static Boot Info"
mtd5: 00040000 00020000 "Hardware Info"
mtd6: 00a00000 00020000 "Kernel"
mtd7: 05000000 00020000 "App Image"
mtd8: 1a080000 00020000 "JFFS2"
```

The partitions can be read from the busybox shell with `dd` and written from shell with `mtd_debug`. Example for mtd7:
```
# read
$dd if=/dev/mtd7 of=/f/partname

#erase then write
mtd_debug erase /dev/mtd7 83886080
mtd_debug write /dev/mtd7 0 83886080 /f/partname
```

Alternatively they can be written from uboot: 
```
# get files via tftp
setenv ipaddr 192.168.1.50
setenv serverip 192.168.1.3
tftpboot 0x81000000 partname

# make sure to erase before write, calculate correct offsets from /proc/mtd
nand erase 0xf80000 0x5000000
nand write 0x81000000 0xf80000 0x5000000
```

## Recovery 
It is advisible to backup all 9 partitions before making any changes, in the worst case it is then possible to recover them from
uboot via ymodem or tftp.

## Vendor kernel
The device in the newest firmware [10.0r8](firmware) is running linux kernel 3.16.36 built with gcc 4.5.3.
Check out the [vendor kernel config](config/vendor-3.16.36.config) and the [version string](docs/kernel-version.txt): \
`Linux version 3.16.36 (build@cd102) (gcc version 4.5.3 (crosstool-NG 1.13.4 - buildroot 2012.02) ) #1 SMP PREEMPT Thu Jan 9 23:02:02 PST 2020`

