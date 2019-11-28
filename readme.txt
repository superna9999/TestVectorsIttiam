There are two configurations for the CtsMediaBitstreamsTestCases.
The default configuration is "standard", which contains 10-12 bit
bitstreams in codecs h264, hevc, vp8, and vp9. The "full"
configuration is a superset of "standard", and about 50 times larger.
The default configuration is "standard".  Use the annotation
android.media.cts.bitstreams.FullPackage to select the full subset.

Please specify the path to the test bitstreams in TestVectorsIttiam via
the cts-tradefed command line as follows:
`--module-arg CtsMediaBitstreamsTestCases:set-option:host-bitstreams-path:/path/to/TestVectorsIttiam`
Default value is ./TestVectorsIttiam.

Please specify the destination to upload bitstreams on device via the
cts-tradefed command line as follows:
`--module-arg CtsMediaBitstreamsTestCases:set-option:device-bitstreams-path:/path/on/device`
Default value is /data/local/tmp.

Examples using standard values:
$
$ cts-tradefed run cts -m CtsMediaBitstreamsTestCases \
>  --module-arg CtsMediaBitstreamsTestCases:exclude-annotation:android.media.cts.bitstreams.FullPackage \
>  --module-arg CtsMediaBitstreamsTestCases:set-option:host-bitstreams-path:./TestVectorsIttiam \
>  --module-arg CtsMediaBitstreamsTestCases:set-option:device-bitstreams-path:/data/local/tmp
$
