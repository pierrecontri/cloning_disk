Clone Disk with Linux
=====================

For SSD (SanDisk with 4k recommanded blocks)

Entries data:

- disk to clone (input)  : 240Go, /dev/sdc
- disk to write (output) : 480Go, /dev/sdd

Command:

'''
dd if=/dev/sdc of=/dev/sdd bs=4096 conv=notrunc
'''
