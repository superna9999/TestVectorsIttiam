#!/bin/bash

set -x

if [ $# -lt 2 ]; then
	echo "Usage: $0 <download base url> <tests>"
	exit 1
fi

TMP=`mktemp -d -p $PWD`
REPO=$1
TESTS=$2

cd $TMP

touch report.txt

wget $REPO/$TESTS -O tests

while read p; do
	DIR=`dirname $p`
	SHA=`basename $p`
	STREAM=`basename $p .sha256`

	TESTDIR=`mktemp -d -p $PWD`

	wget $REPO/$DIR/$SHA -O $TESTDIR/$SHA
	wget $REPO/$DIR/$STREAM -O $TESTDIR/$STREAM

	if echo $STREAM | grep -c "mp4" ; then
		if gst-inspect-1.0 | grep v4l2h264dec ; then
			DEC=v4l2h264dec
		elif gst-inspect-1.0 | grep vaapidecodebin && gst-inspect-1.0 vaapidecodebin | grep -c video/x-h264 ; then
			DEC=vaapidecodebin
		else
			DEC=avdec_h264
		fi
	elif echo $STREAM | grep -c "webm" ; then
		if gst-inspect-1.0 | grep v4l2h264dec ; then
			DEC=v4l2vp9dec
		elif gst-inspect-1.0 | grep vaapidecodebin && gst-inspect-1.0 vaapidecodebin | grep -c video/x-vp9 ; then
			DEC=vaapidecodebin
		else
			DEC=avdec_h264
		fi
	fi

	gst-launch-1.0 filesrc location=$TESTDIR/$STREAM  ! parsebin ! $DEC ! videoconvert n-threads=8 ! 'video/x-raw, format=I420' ! filesink location=$TESTDIR/$STREAM.raw | tee $TESTDIR/log &
	PID=$!

	( sleep 10 && kill $PID ) &

	TIMEOUT=0
	wait $PID || TIMEOUT=1

	[ -e $TESTDIR/$STREAM.raw ] && cat $TESTDIR/$STREAM.raw | sha256sum > $TESTDIR/$STREAM.raw.sha256

	if [ "$TIMEOUT" = "1" ] ; then
		echo "$p	TIMEOUT ($TESTDIR)" >> report.txt
		rm $TESTDIR/$STREAM $TESTDIR/$STREAM.raw
	elif diff -q $TESTDIR/$SHA $TESTDIR/$STREAM.raw.sha256 ; then
		echo "$p	OK" >> report.txt
		rm -fr $TESTDIR
	else
		echo "$p	FAIL ($TESTDIR)" >> report.txt
		rm $TESTDIR/$STREAM $TESTDIR/$STREAM.raw
	fi
done < tests

cd -

cat $TMP/report.txt

exit 0
