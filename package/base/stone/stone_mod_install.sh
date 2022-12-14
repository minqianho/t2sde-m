# --- T2-COPYRIGHT-NOTE-BEGIN ---
# T2 SDE: package/*/stone/stone_mod_install.sh
# Copyright (C) 2004 - 2022 The T2 SDE Project
# Copyright (C) 1998 - 2003 ROCK Linux Project
# 
# This Copyright note is generated by scripts/Create-CopyPatch,
# more information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2.
# --- T2-COPYRIGHT-NOTE-END ---

part_mounted_action() {
	if gui_yesno "Do you want to un-mount the filesystem on $1?"
	then umount /dev/$1; fi
}

part_swap_action() {
	if gui_yesno "Do you want to de-activate the swap space on $1?"
	then swapoff /dev/$1; fi
}

part_mount() {
	local dev=$1
	local dir="/ /boot /home /srv /var"
	[ -d /sys/firmware/efi ] && dir="${dir/boot/boot/efi}"
	local d
	for d in $dir; do
		grep -q " /mnt${d%/} " /proc/mounts || break
	done
	gui_input "Mount device $dev on directory
(for example ${dir// /, }, ...)" "${d:-/}" dir
	if [ "$dir" ]; then
		dir="$(echo $dir | sed 's,^/*,,; s,/*$,,')"
		# check if at least a rootfs / is already mounted
		if [ -z "$dir" ] || grep -q " /mnt " /proc/mounts
		then
			mkdir -p /mnt/$dir
			mount /dev/$dev /mnt/$dir
		else
			gui_message "Please mount a root filesystem first."
		fi
	fi
}

part_mkfs() {
	local dev=$1
	cmd="gui_menu part_mkfs 'Create filesystem on $dev'"

	maybe_add () {
	  if #grep -q $1 /proc/filesystems &&
	     type -p $3 > /dev/null; then
		cmd="$cmd '$1 ($2 filesystem)' \
		'type wipefs 2>/dev/null && wipefs -a /dev/$dev; $3 $4 /dev/$dev'"
	  fi
	}

	maybe_add btrfs	'Better, b-tree, CoW journaling' 'mkfs.btrfs' '-f'
	maybe_add ext4	'journaling, extents'	'mkfs.ext4'
	maybe_add ext3	'journaling'		'mkfs.ext3'
	maybe_add ext2	'non-journaling'	'mkfs.ext2'
	maybe_add jfs	'IBM journaling'	'mkfs.jfs'
	maybe_add reiserfs 'journaling'		'mkfs.reiserfs'
	maybe_add xfs	'Sgi journaling'	'mkfs.xfs' '-f'
	maybe_add fat	'File Allocation Table'	'mkfs.fat'

	eval "$cmd" && part_mount $dev
}

part_decrypt() {
	local dev=$1

	local dir="root home swap"
	local d
	for d in $dir; do
		[ -e /dev/mapper/$dir ] || break
	done
	gui_input "Mount device $dev on directory
(for example ${dir// /, }, ...)" "${d:-/}" dir
	if [ "$dir" ]; then
		dir="$(echo $dir | sed 's,^/*,,; s,/*$,,')"
		cryptsetup luksOpen --disable-locks /dev/$dev $dir
	fi
}

part_crypt() {
	local dev=$1
	cryptsetup luksFormat --disable-locks --type luks1 /dev/$dev || return

	part_decrypt $dev
}

part_unmounted_action() {
	gui_menu part "$1" \
		"Mount an existing filesystem from the partition" \
				"part_mount $1" \
		"Create a filesystem on the partition" \
				"part_mkfs $1" \
		"Activate an existing swap space on the partition" \
				"swapon /dev/$1" \
		"Create a swap space on the partition" \
				"mkswap /dev/$1; swapon /dev/$1" \
		"Activate a LUKS encrypted partition" \
				"part_decrypt $1" \
		"Encrypt partition using LUKS cryptsetup" \
				"part_crypt $1"
}

part_add() {
	local action="unmounted" location="currently not mounted"
	if grep -q "^/dev/$1 " /proc/swaps; then
		action=swap location="swap  <no mount point>"
	elif grep -q "^/dev/$1 " /proc/mounts; then
		action=mounted
		location="`grep "^/dev/$1 " /proc/mounts | cut -d ' ' -f 2 |
			  sed "s,^/mnt,," `"
		[ "$location" ] || location="/"
	fi

	# save partition information
	disktype /dev/$1 > /tmp/stone-install
	type="`grep /tmp/stone-install -v -e '^  ' -e '^Block device' \
	       -e '^Partition' -e '^---' |
	       sed -e 's/[,(].*//' -e '/^$/d' -e 's/ $//' | tail -n 1`"
	size="`grep 'Block device, size' /tmp/stone-install |
	       sed 's/.* size \(.*\) (.*/\1/'`"

	[ "$type" ] || type="undetected"
	cmd="$cmd '`printf "%-6s %-24s %-10s" ${1#*/} "$location" "$size"` $type' 'part_${action}_action $1 $2'"
}

disk_action() {
	if grep -q "^/dev/$1 " /proc/swaps /proc/mounts; then
		gui_message "Partitions from $1 are currently in use, so you
can't modify this disks partition table."
		return
	fi

	cmd="gui_menu disk 'Edit partition table of $1'"
	for x in parted cfdisk fdisk pdisk mac-fdisk; do
		type -p $x > /dev/null &&
		  cmd="$cmd \"Edit partition table using '$x'\" \"$x /dev/$1\""
	done

	eval $cmd
}

vg_action() {
	cmd="gui_menu vg 'Volume Group $1'"

	if [ -d /dev/$1 ]; then
		cmd="$cmd 'Display attributes of $1' 'gui_cmd \"display $1\" vgdisplay $1'"

		if grep -q "^/dev/$1/" /proc/swaps /proc/mounts; then
		  cmd="$cmd \"LVs of $1 are currently in use, so you can't
de-activate it.\" ''"
		else
		  cmd="$cmd \"De-activate VG '$1'\" 'vgchange -an $1'"
		fi
	else
		cmd="$cmd 'Display attributes of $1' 'gui_cmd \"display $1\" vgdisplay -D $1'"

		cmd="$cmd \"Activate VG '$1'\" 'vgchange -ay $1'"
	fi

	eval $cmd
}

disk_add() {
	local x y=0
	cmd="$cmd 'Edit partition table of $1:' 'disk_action $1'"
	# TODO: maybe better /sys/block/$1/$1* ?
	for x in $(cd /dev; ls $1[0-9p]* 2> /dev/null)
	do
		part_add $x; y=1
	done
	[ $y = 0 ] && cmd="$cmd 'Partition table is empty.' ''"
	cmd="$cmd '' ''"
}

vg_add() {
	local x= y=0
	cmd="$cmd 'Logical volumes of $1:' 'vg_action $1'"
	if [ -d /dev/$1 ]; then
		for x in $(cd /dev; ls -1 $1/*); do
			part_add $x; y=1
		done
		if [ $y = 0 ]; then
			cmd="$cmd 'No logical volumes.' ''"
		fi
	else
		cmd="$cmd 'Volume Group is not active.' ''"
	fi
	cmd="$cmd '' ''"
}

main() {
	$STONE general set_keymap

	local cmd install_now=0
	while
		cmd="gui_menu install 'Storage setup (partitions and mount-points)

This dialog allows you to modify your storage layout and to create filesystems and swap-space - as well as mouting / activating it. Everything you can do using this tool can also be done manually on the command line.'"

		# protect for the case no block devices are present ...
		found=0
		local volumes=
		for x in /sys/block/*; do
			[ ! -e $x/device -a ! -e $x/dm ] && continue
			x=${x#/sys/block/}
			[[ "$x" = fd[0-9]* ]] && continue
			# TODO: media? udevadm info -q property --name=/dev/sr0

			# find user defined alias name
			local devnode=$(stat -c "%t:%T" /dev/$x)
			for d in /dev/mapper/*; do
				[ "$(stat -c "%t:%T" $d)" = "$devnode" ] &&
					x=${d#/dev/} && break
			done
			
			[[ $x = mapper/* ]] && volumes="$volumes $x" || disk_add $x
			found=1
		done
		for x in $volumes; do
			part_add $x
		done
		for x in $(cat /etc/lvmtab 2> /dev/null); do
			vg_add "$x"
			found=1
		done
		[ -x /sbin/vgs ] && for x in $(vgs --noheadings -o name 2> /dev/null); do
			vg_add "$x"
			found=1
		done
		if [ $found = 0 ]; then
		  cmd="$cmd 'No storage found!' ''"
		fi

		cmd="$cmd 'Install the system ...' 'install_now=1'"

		eval "$cmd" && [ "$install_now" -eq 0 ]
	do : ; done

	if [ "$install_now" -ne 0 ]; then
		$STONE packages
		mount -v /dev /mnt/dev --bind
		cat > /mnt/tmp/stone_postinst.sh << EOT
#!/bin/bash
mount -v /proc
mount -v /sys
. /etc/profile
stone setup
umount -v /dev
umount -v /proc
umount -v /sys
EOT
		chmod +x /mnt/tmp/stone_postinst.sh
		grep ' /mnt[/ ]' /proc/mounts |
			sed 's,/mnt/\?,/,' > /mnt/etc/mtab
		cd /mnt; chroot . ./tmp/stone_postinst.sh
		rm -fv ./tmp/stone_postinst.sh
		if gui_yesno "Do you want to un-mount the filesystems and reboot now?"
		then
			shutdown -r now
		else
			echo
			echo "You might want to umount all filesystems now and reboot"
			echo "the system now using the commands:"
			echo
			echo "	umount -arv"
			echo "	reboot -f"
			echo
			echo "Or by executing 'shutdown -r now' which will run the above commands."
			echo
		fi
	fi
}
