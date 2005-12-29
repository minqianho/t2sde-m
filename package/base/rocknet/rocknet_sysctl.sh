# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../rocknet/rocknet_sysctl.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

public_forward() {
	if [ "$if" != "none" ]; then
		error "Keyword >>forward<< not allowed" \
			"in an interface section."
		return
	fi
	[ "$interface" != auto ] && return
	addcode up   9 5 "echo 1 > /proc/sys/net/ipv4/ip_forward"
	addcode down 9 5 "echo 0 > /proc/sys/net/ipv4/ip_forward"
}

