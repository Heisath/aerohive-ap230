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
Pin assignment is available here: https://docs.aerohive.com/330000/docs/help/english/ng/Content/hardware/pin-assigment.htm \
View on port:
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
following shortly

## Accessing the hidden shell
following shortly

