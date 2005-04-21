# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/desktop/kernel.conf.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---
# here we disable all OSS modules - because they suck

echo "desktop target -> disabling oss sound modules ..."

sed -i -e "s/CONFIG_SOUND_OSS=./# CONFIG_SOUND_OSS is not set/" \
       -e"s/CONFIG_SOUND_PRIME=./# CONFIG_SOUND_PRIME is not set/" $1

# preemtion is not stable on PowerPC - so only enable it for x86 for now
if [ $SDECFG_ARCH = x86 ] ; then
	sed -i "s/# CONFIG_PREEMPT is not set/CONFIG_PREEMPT=y/" $1
else
	sed -i "s/CONFIG_PREEMPT=y/# CONFIG_PREEMPT is not set/" $1
fi

