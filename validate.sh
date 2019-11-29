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

	#ffmpeg -c:v h264_v4l2m2m -i $TESTDIR/$STREAM -pix_fmt yuv420p -f rawvideo -y $TESTDIR/$STREAM.raw
	gst-launch-1.0 filesrc location=$TESTDIR/$STREAM  ! parsebin ! v4l2h264dec ! videoconvert n-threads=8 ! 'video/x-raw, format=I420' ! filesink location=$TESTDIR/$STREAM.raw | tee $TESTDIR/log &
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
		rm $TESTDIR
	else
		echo "$p	FAIL ($TESTDIR)" >> report.txt
		rm $TESTDIR/$STREAM $TESTDIR/$STREAM.raw
	fi
done < tests

cd -

cat $TMP/report.txt

exit 0
