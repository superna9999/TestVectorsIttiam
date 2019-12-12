#!/bin/sh

while read p; do
	F1=`echo $p | cut -d_ -f2`
	F2=`echo $F1 | cut -dx -f2`
	W=`echo $F1 | cut -dx -f1`
	H=`echo $F2 | cut -dp -f1`

	[ $W -lt 256 ] && continue;
	[ $W -gt 3840 ] && continue;
	[ $H -lt 144 ] && continue;
	[ $H -gt 2160 ] && continue;

	echo $p

done < $1
