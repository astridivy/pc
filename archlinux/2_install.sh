#!/bin/bash
pacstrap /mnt base base-devel linux linux-firmware dhcpcd networkmanager dialog wpa_supplicant vim lua ruby git lynx acpi tamsyn-font tree light

genfstab /mnt -L >> /mnt/etc/fstab
