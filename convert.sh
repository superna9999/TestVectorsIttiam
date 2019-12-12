#!/bin/bash

set -ex

TMP=`mktemp -u -p $PWD`

if echo $1 | grep "mp4" ; then
	[ -e $1.sha256 ] && rm $1.sha256
	gst-launch-1.0 -q filesrc location=$1 ! parsebin ! avdec_h264 ! videoconvert n-threads=8 ! 'video/x-raw, format=I420' ! filesink location=$1.raw-gst > /dev/null
	ffmpeg -v 0 -i $1 -pix_fmt yuv420p -f rawvideo -y $1.raw-ffmpeg > /dev/null
	if diff -q $1.raw-ffmpeg $1.raw-gst ; then
		cat $1.raw-ffmpeg | sha256sum > $1.sha256
		rm $1.raw-*
	else
		exit 1
	fi
elif echo $1 | grep "webm" ; then 
	if gst-launch-1.0 filesrc location=$1 ! parsebin ! avdec_vp9 ! videoconvert n-threads=8 ! 'video/x-raw, format=I420' ! filesink location=$TMP ; then
		cat $TMP | sha256sum > $1.sha256
		rm $TMP
	fi
fi

exit 0
