#!/bin/bash
#
# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
#
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
#
# ROCK Linux: rock-src/scripts/Build-Pkg
# ROCK Linux is Copyright (C) 1998 - 2003 Clifford Wolf
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. A copy of the GNU General Public
# License can be found at Documentation/COPYING.
#
# Many people helped and are helping developing ROCK Linux. Please
# have a look at http://www.rocklinux.org/ and the Documentation/TEAM
# file for details.
#
# --- ROCK-COPYRIGHT-NOTE-END ---

#
# bless-rs6k is Copyright (C) 2003 Rene Rebe
#

yb_bin="boot/yaboot.rs6k"

# function to return a 512 sized sector count
sector_count() {
	echo $((`ls -l $1 | sed 's/  */ /g' | cut -d ' ' -f5` / 512))
}

if [ "$1" == 0 ] ; then
	echo "Not the first CD - not blessing ..."
fi


# test
cd_sec=`sector_count $2`

# calculate the size for a 512 byte alligned yaboot binary, padded with zeros
yb_sec=`sector_count $yb_bin`
yb_sec=$(( yb_sec + 1 ))

echo "ISO sector count: $cd_sec Yaboot RS/6k binary sectors: $yb_sec"

echo "RS/6k-blessing $2 ..."
sfdisk -uS -f -q --no-reread $2 <<-EOT
;
$cd_sec,$yb_sec,0x41,*
;
;
EOT

echo "done"

echo "Attaching Yaboot binary ..."
cat yb.alligned >> $2
cat $/usr/lib/yaboot/yaboot.rs6k /dev/zero | \
        dd of=yb.alligned bs=512 count=$yb_sec

