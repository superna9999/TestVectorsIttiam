#!/bin/sh

set -ex

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

	TESTDIR=`mktemp -d -p $PWD --suffix=$STREAM`

	wget $REPO/$DIR/$SHA -O $TESTDIR/$SHA
	wget $REPO/$DIR/$STREAM -O $TESTDIR/$STREAM

	ffmpeg -c:v h264_v4l2m2m -i $TESTDIR/$STREAM -pix_fmt yuv420p -f rawvideo -y $TESTDIR/$STREAM.raw

	cat $TESTDIR/$STREAM.raw | sha256sum > $TESTDIR/$STREAM.raw.sha256

	if diff -q $SHA $STREAM.raw.sha256 ; then
		echo "$p	OK" >> report.txt
		rm $TESTDIR
	else
		echo "$p	FAIL ($TESTDIR)" >> report.txt
	fi
done < tests

cd -

cat $TMP/report.txt

exit 0
