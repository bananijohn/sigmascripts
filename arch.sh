#!/bin/bash

# Script to automate installing Arch Linux,
# up until the arch-chroot step.

# Determine whether the user wants to manually partition or let the script do it for them.
if [[ ! $SKIPFDISK ]]; then
	echo "This script will create a GPT partiton table with three partitions. You will define their sizes."
	echo "THIS WILL WIPE THE ENTIRE DRIVE!"
	echo "If you wish to partition manually before continuing, you can skip this step by running 'SKIPFDISK=true ./arch.sh' and running the script again."
	echo "Skipping this step will require you to specify the boot, root, and swap partitions later."

	read -p "Continue? [y/N]: " ans

	if [[ $ans =~ ^([yY][eE][sS]|[yY])$ ]]; then
		read -p "Which drive are we working on? (e.g. /dev/sda): " dri
		read -p "Size of the EFI system partition: " size1
		read -p "Size of the root partition: " size2
		read -p "Size of the swap partition: " size3

		sfdisk $dri <<EOF
		label: gpt
		,$(echo $size1)
		,$(echo $size2)
		,$(echo $size3)
EOF

	boot=${dri}1
	root=${dri}2
	swap=${dri}3
	fi
fi

# Ask the user where their partitions are located if they manually partitioned.
if [[ $SKIPFDISK ]]; then
	read -p "Where is your EFI system partition? (e.g. /dev/sda1): " boot
	read -p "Where is your root partition? (e.g. /dev/sda2): " root
	read -p "Where is your swap partition? (e.g. /dev/sda3): " swap
fi

# Create filesystems
mkfs.vfat $boot
mkfs.ext4 $root
mkswap $swap

# Mount all partitions
mount $root /mnt
mount $boot --mkdir /mnt/boot
swapon $swap

# Bootstrap the system and install necessary packages
read -p "Which packages do you want to pacstrap? (Default: base linux linux-firmware): " packages
pacstrap -K /mnt base linux linux-firmware $packages
genfstab -U >>/mnt/etc/fstab

# Optionally chroot
read -p "Chroot? [y/N]: " ans
if [[ $ans =~ ^([yY][eE][sS]|[yY])$ ]]; then
	arch-chroot /mnt
fi
