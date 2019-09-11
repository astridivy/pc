#!/bin/bash
timedatectl set-ntp true

echo "Partition the drive with fdisk"

cat <<EOF
Example layouts
                                  BIOS with [101]MBR
        Mount point      Partition    [102]Partition type        Suggested size
   /mnt                  /dev/sdX1 Linux                     Remainder of the device
   [SWAP]                /dev/sdX2 Linux swap                More than 512 MiB
                                  UEFI with [103]GPT
        Mount point      Partition    [104]Partition type        Suggested size
   /mnt/boot or /mnt/efi /dev/sdX1 [105]EFI system partition 260-512 MiB
   /mnt                  /dev/sdX2 Linux x86-64 root (/)     Remainder of the device
   [SWAP]                /dev/sdX3 Linux swap                More than 512 MiB
EOF

lsblk

bash

echo "Format the partitions"

cat <<EOF
  EX.
    # mkfs.ext4 /dev/sdX1
    # mkswap /dev/sdX2
    # swapon /dev/sdX2
EOF

bash

echo "Mount the file systems to /mnt (don't forget /efi if you need it)"

bash
