#!/bin/sh

set -x

if [ $# -lt 2 ]; then
	echo "Usage: $0 <download base url> <[tests] on repo or [tests].local for local file>"
	exit 1
fi

TMP="`mktemp -d -p $PWD`"
REPO=$1
TESTS=$2

if echo $TESTS | grep -c ".local" ; then
	cp $TESTS $TMP/tests
fi

cd $TMP

REPORT_FILE="report-`uname -n`.csv"
echo "Test;Result;Temp Dir" > $REPORT_FILE

[ -e tests ] || wget $REPO/$TESTS -O tests

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

	GST_DEBUG_DUMP_DOT_DIR=$TESTDIR GST_DEBUG=4 gst-launch-1.0 filesrc location=$TESTDIR/$STREAM  ! parsebin ! $DEC ! videoconvert n-threads=8 ! 'video/x-raw, format=I420' ! filesink location=$TESTDIR/$STREAM.raw 2> $TESTDIR/log &
	PID=$!

	(
		sleep 30
		[ -e $TESTDIR/done ] || kill $PID
	) &

	TIMEOUT=0
	if wait $PID ; then
		touch $TESTDIR/done
	else
		TIMEOUT=1
	fi

	[ -e $TESTDIR/$STREAM.raw ] && cat $TESTDIR/$STREAM.raw | sha256sum > $TESTDIR/$STREAM.raw.sha256

	if [ "$TIMEOUT" = "1" ] ; then
		echo "$p;TIMEOUT;`basename $TESTDIR`" >> $REPORT_FILE
		rm $TESTDIR/$STREAM $TESTDIR/$STREAM.raw
	elif diff -q $TESTDIR/$SHA $TESTDIR/$STREAM.raw.sha256 ; then
		echo "$p;OK;" >> $REPORT_FILE
		rm -fr $TESTDIR
	else
		echo "$p;FAIL;`basename $TESTDIR`" >> $REPORT_FILE
	fi
done < tests

cat $REPORT_FILE

cd -

exit 0
