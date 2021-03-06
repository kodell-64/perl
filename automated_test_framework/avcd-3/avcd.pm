#
# VERSION 3
#
# Korey O'Dell
package avcd;
use warnings;
use strict;
use IPC::Run qw( run start harness timeout );
use Cwd;
use Data::Dumper;
require "avcd-3/avcdtests.pm";
1; 

our $help = <<XXX;
ACME Media\'s System/Regression Test Tool for AVCD

Example usage (to see all available avcd tests):
perl regression-test.pl  avcd-3.9.0.8840.tar 96c9137d8481c7fb52807457b5dbd35c --show-tests
 - shows all tests with short descriptions of each.

Example usage (to see all available avcd tests):
perl regression-test.pl  avcd-3.9.0.8840.tar 96c9137d8481c7fb52807457b5dbd35c --show-test=6420
 - shows test \#6420\'s full detail including descriptive narrative.

Example usage:
perl regression-test.pl  avcd-3.9.0.8840.tar 96c9137d8481c7fb52807457b5dbd35c --run-tests=6420 --test-params=timetorun=600,--stuffed-rate=10000 
Explained: Runs test \#6420. 
 - Overrides test default 'timetorun' setting with 600 seconds. This causes the test to run ~600 seconds.
 - Sets/Overrides avcd\'s --stuffed-rate parameter to 10000.

Logfiles:

    A logfile for the test run is written to results/<component name>/<package name>/$0.<package name>.log.
    This contains the Report and Summary objects entries for the entire run.
    For avcd, avcd\'s log file is typically written to avcd/tests/test-<id>/results/<package name>/
    NOTE: avcd\'s log file path can be overridden via the command line so to positively find its log file, review the tool\'s logfile and look for the avcd command line used and\/or the --logfile parameter being passed to avcd.
XXX

# generic function pointers to point to the various widely-used test functions.
# avoids having to change the function call multiple places everytime the function is expanded
    
our $func1 = \&AvcdTests::alpha;
our $func2 = \&AvcdTests::beta;


my %avcdtests = (

	1000 => {
		"id"               	=> "1000",
		"name"	           	=> "Install: Versioning of avcd",
		"narrative"        	=> "This test validates that avcd version numbering is correct.",
		"estimatedhours"    => .25,
        "teststeps"        	=> [("Verify that numbering used in the filename matches that of the release. Run avcd -v and compare the output to that of the tar.",
                                )],
		"history"          	=> "added by kodell, March 15, 2013",
		"prerunactions"    	=> [],
		"startactions"	   	=> [],
		"runactions"       	=> ['manualTest'],
		"postrunactions"   	=> [],
		},
		
	1005 => {
		"id"               	=> "1005",
		"name"	           	=> "Install: Upgrade of avcd",
		"narrative"        	=> "This test validates that avcd upgrades correctly.",
        "estimatedhours"    => .5,
		"teststeps"        	=> [("",
								)],
		"history"          	=> "added by kodell, March 15, 2013",
		"prerunactions"    	=> [],
		"startactions"	   	=> [],
		"runactions"       	=> ['manualTest'],
		"postrunactions"   	=> [],
		},

	1010 => {
		"id"               	=> "1010",
		"name"	           	=> "Install: Installation of avcd and Verification of Shared Library Dependencies",
		"narrative"        	=> "This test validates that avcd will install correctly on the current base image (12.3.4) and installs the necessary shared libraries and the binary runs",
        "estimatedhours"    => .5,
		"teststeps"        	=> [("Install avcd with /opt/avail/avail_install.sh /images/$ARGV[0]. Doing so will install avcd into /opt/avail/bin, did this binary get installed?",
                                 "After installation, run the following command, 'ldd /opt/avail/bin/avcd' It will output similar to the following:\n\tlinux-vdso.so.1 (0x00007fff192a7000) libx264.so.128 => /usr/lib64/libx264.so.128 (0x00007f5dd4dba000) libtwolame.so.0 => /usr/lib64/libtwolame.so.0 (0x00007f5dd4b97000) libfaac.so.0 => /usr/lib64/libfaac.so.0 (0x00007f5dd4984000) libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f5dd4767000) libavcodec.so.53 => /usr/lib64/libavcodec.so.53 (0x00007f5dd39a0000) libavutil.so.51 => /usr/lib64/libavutil.so.51 (0x00007f5dd3780000) libswscale.so.2 => /usr/lib64/libswscale.so.2 (0x00007f5dd3544000) libneon.so.27 => /usr/lib64/libneon.so.27 (0x00007f5dd331a000) libsamplerate.so.0 => /usr/lib64/libsamplerate.so.0 (0x00007f5dd2fae000) libm.so.6 => /lib64/libm.so.6 (0x00007f5dd2cfe000) libc.so.6 => /lib64/libc.so.6 (0x00007f5dd295a000) /lib64/ld-linux-x86-64.so.2 (0x00007f5dd512e000) libz.so.1 => /lib64/libz.so.1 (0x00007f5dd2744000) libssl.so.1.0.0 => /usr/lib64/libssl.so.1.0.0 (0x00007f5dd24db000) libcrypto.so.1.0.0 => /usr/lib64/libcrypto.so.1.0.0 (0x00007f5dd210e000) libxml2.so.2 => /usr/lib64/libxml2.so.2 (0x00007f5dd1dbd000) libdl.so.2 => /lib64/libdl.so.2 (0x00007f5dd1bb9000) Look for any lines that say 'not found'. If there are no lines that say 'not found', pass this step. Otherwise fail it.",
						 "Run the binary to ensure runtime satisfaction. Run it with '/opt/avail/bin/avcd'. You should see the usage information for avcd if successful. Otherwise, you'll see something similar to '/opt/avail/bin/avcd: error while loading shared libraries...",
									   )],
		"history"          	=> "added by kodell, Thu Dec 27 13:31:19 MST 2012, modified by sstepan, Fri Jan 25, 2013, for nimbus-1.1.0",
		"prerunactions"   	=> [],
		"startactions"	   	=> [],
		"runactions"       	=> ['manualTest'],
		"postrunactions"   	=> [],
		},
	1020 => {
		"id"               	=> "1020",
		"name"	           	=> "Install: Comparison of previous and new shared library versions.",
		"narrative"        	=> "This test validates that a previous and new version of avcd do have the same versions of shared libraries.",
                "estimatedhours"    => .1,
		"teststeps"        	=> [("Install the previous version, run 'ldd /opt/avail/bin/avcd', note the results. Install the new version, run 'ldd /opt/avail/bin/avcd'. Compare the two reports, they should be the same if there are no wanted version upgrades in the shared lib stack.")],
		"history"          	=> "added by kodell, Mon Apr 7 2014",
		"prerunactions"   	=> [],
		"startactions"	   	=> [],
		"runactions"       	=> ['manualTest'],
		"postrunactions"   	=> [],
		},

	50000 => {
		"id"				=> "50000",
		"name"				=> "File-File, MPEG2-MPEG4",
		"narrative"			=> "File-File encode a MPEG2 asset to MPEG4",
        "resultspath"       => "results",
        "filetofilemode"    => "true",
		"srcfile"			=> "Babar_27s.ts",
		#srcfile"			=> "C3_1_short.mpg",
		#"srcfile"			=> "HD_C3_VOD_UPALLNIGHT_03082012.mpg",
        "encodefile"        => "encode.ts",
		"configpreset"		=> "0",
		"history"			=> "added by kodell, May 15, 2012, for 3.0",
		"runloop"			=> "10",
		"prerunactions"		=> ['createConfig'],
		"startactions"		=> ['startAvcd'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 'checkEncodeFile', ['pause',(5)] ],
		"postrunactions" 	=> [['analyzeEncodeFile', ([0,480,481,482,8191])], 'stopAvcd'],
	},
	50010 => {
		"id"				=> "50010",
		"name"				=> "File-File, MPEG2HD-MPEG4SD",
		"narrative"			=> "File-File encode a MPEG2HD asset to MPEG4",
        "resultspath"       => "results",
        "filetofilemode"    => "true",
		"srcfile"			=> "C3_1.mpg",
        "encodefile"        => "encode.ts",
		"configpreset"		=> "1",
		"history"			=> "added by kodell, May 16, 2012, for 3.0",
		"runloop"			=> "100",
		"prerunactions"		=> ['createConfig'],
		"startactions"		=> ['startAvcd'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', ['pause',(5)], 'checkEncodeFile', ['pause',(15)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	50020 => {
		"id"				=> "50020",
		"name"				=> "File-File, MPEG2-MPEG2",
		"narrative"			=> "File-File encode a MPEG2 asset to MPEG2",
        "resultspath"       => "results",
        "filetofilemode"    => "true",
		"srcfile"			=> "Babar_27s.ts",
		#srcfile"			=> "C3_1_short.mpg",
		#"srcfile"			=> "HD_C3_VOD_UPALLNIGHT_03082012.mpg",
        "encodefile"        => "encode.ts",
		"configpreset"		=> "10",
		"history"			=> "added by kodell, June 8, 2012, for 3.0",
		"runloop"			=> "10",
		"prerunactions"		=> ['createConfig'],
		"startactions"		=> ['startAvcd'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 'checkEncodeFile', ['pause',(5)] ],
		"postrunactions" 	=> [['analyzeEncodeFile', ([0,480,481,482,8191])], 'stopAvcd'],
	},

	50030 => {
		"id"				=> "50030",
		"name"				=> "MPEG2HD720p-MPEGSHD480p encode with no source feed.",
		"narrative"			=> "MPEG2HD720p-MPEG4SD480p XXXX.",
        "resultspath"       => "results",
		"configpreset"		=> "205",
		"history"			=> "added by kodell, January 30, 2013, for 3.0",
		"runloop"			=> "5",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                'validateEgress', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,480,481,482], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

	50035 => {
		"id"				=> "50035",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i encode with no source feed.",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i encode with no source feed. Test allows for different source feeds to be used.",
        "resultspath"       => "results",
		"configpreset"		=> "320",
		"history"			=> "added by kodell, February 14, 2013, for 3.0",
		"runloop"			=> "60",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #'validateEgress', 
                                #['validateEgress', 10], 
                                #['egressContainsPids', ([0,480,481,482], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

	50040 => {
		"id"				=> "50040",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i random feeds",
		"narrative"			=> "MPEG*HD1080i-MPEG4HD1080i randomized feeds.",
		"srcfile"			=> [("starz-e-hd-moneyball-1.dump", "tlc-hd-spts-3sctepids-30s.dump", "starzfamilyhd-apr4-1-source-recap.dump")],
        "resultspath"       => "results",
		"configpreset"		=> "300",
		"history"			=> "added by kodell, January 14, 2013, for 3.0",
		"runloop"			=> "50000",
		"prerunactions"		=> ['isAvcdNotRunning', 'startAvcd', 'createConfig'],
		"startactions"		=> [],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['provideRandomStream'],
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,480,481,482], 1, [600, 601, 602], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

	51000 => {
		"id"				=> "51000",
		"name"				=> "Multicast: MPEG4SD-MPEG2SD, no stream validation",
		"narrative"			=> "MPEG4SD-MPEG2SD of a captured stream",
        "resultspath"       => "results",
		"srcfile"			=> "fnc-mpeg4-1.6Mbps-30s.dump",
		"configpreset"		=> "100",
		"history"			=> "added by kodell, November 26, 2012, for 3.0",
		"runloop"			=> "10",
		"prerunactions"		=> ['createConfig'],
		"startactions"		=> ['startStream', 'startAvcd'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	51010 => {
		"id"				=> "51010",
		"name"				=> "Multicast: MPEG4SD-MPEG2SD",
		"narrative"			=> "MPEG4SD-MPEG2SD of a captured stream",
        "resultspath"       => "results",
		"srcfile"			=> "fnc-mpeg4-1.6Mbps-120s.dump",
		"configpreset"		=> "100",
		"history"			=> "added by kodell, November 26, 2012, for 3.0",
		"runloop"			=> "10",
		"prerunactions"		=> ['createConfig'],
		"startactions"		=> ['startStream', 'startAvcd'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                'validateEgress', 
                                ['egressContainsPids', ([0,480,481,482,8191])],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	51020 => {
		"id"				=> "51020",
		"name"				=> "Live Multicast: MPEG4SD-MPEG2SD",
		"narrative"			=> "MPEG4SD-MPEG2SD of a live stream",
        "resultspath"       => "results",
		"configpreset"		=> "100",
		"history"			=> "added by kodell, November 26, 2012, for 3.0",
		"runloop"			=> "10",
		"prerunactions"		=> ['createConfig'],
		"startactions"		=> ['startAvcd'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                'validateEgress', 
                                ['egressContainsPids', ([0,480,481,482])],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	51030 => {
		"id"				=> "51030",
		"name"				=> "Live Multicast: MPEG2HD-MPEG4SD",
		"narrative"			=> "MPEG2HD-MPEG4SD of a live stream",
        "srcfile"           => "starzfamilyhd-apr4-1-source-recap.dump",
        "resultspath"       => "results",
		"configpreset"		=> "200",
		"history"			=> "added by kodell, November 29, 2012, for 3.0",
		"runloop"			=> "10",
		"prerunactions"		=> ['createConfig'],
		"startactions"		=> ['startStream', 'startAvcd'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                'validateEgress', 
                                ['egressContainsPids', ([0,480,481,482])],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	52000 => {
		"id"				=> "52000",
		"name"				=> "MPEG2HD720p-MPEG4HD720p",
		"narrative"			=> "MPEG2HD720p-MPEG4HD720p of a captured stream",
        #"srcfile"           => "a_e_hd-90s-mpeg2.1251236635.dump",
        "srcfile"           => "espn-e-hd-1.dump",
        #nat_geo_hd-90s-mpeg2.1251236815.dump",
        "resultspath"       => "results",
		"configpreset"		=> "210",
		"history"			=> "added by kodell, January 14, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                'validateEgress', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	52005 => {
		"id"				=> "52005",
		"name"				=> "MPEG2HD720p-MPEG4HD720p",
		"narrative"			=> "MPEG2HD720p-MPEG4HD720p of a captured stream, check for presence of null packets",
        "srcfile"           => "a_e_hd-90s-mpeg2.1251236635.dump",
        "resultspath"       => "results",
		"configpreset"		=> "200",
		"history"			=> "added by kodell, January 14, 2013, for 3.0",
		"runloop"			=> "50",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                'validateEgress', 
                                ['egressContainsPids', ([0,480,481,482,8191])],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},


	53000 => {
		"id"				=> "53000",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i of a captured stream that contains three scte-35 pids. We renumber them to 600,601,602 in this test and ensure they arrive in the egress.",
        #"srcfile"           => "tlc-hd-spts-3sctepids-30s.dump",
        #"srcfile"           => "tlc-mpeg4-1.dump",
        #"srcfile"           => "starzfamilyhd-apr4-1-source-recap.dump",
        #"srcfile"           => "starz-west-hd-mpeg2-1.dump",
        #"srcfile"           => "nbc-sports-1.dump",
        #"srcfile"           => "golf_hd.dump",
        #"srcfile"           => "versus_hd-3600s-mpeg2.1251486328.dump",
        "srcfile"           => "travel-channel-east-hd-1.dump",

        "resultspath"       => "results",
		"configpreset"		=> "310",
		"history"			=> "added by kodell, January 14, 2013, for 3.0",
		"runloop"			=> "50000",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000], 1, [600, 601, 602], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	53005 => {
		"id"				=> "53005",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i of a Starz West HD MPEG2 stream.",
        "srcfile"           => "starz-west-hd-mpeg2-1.dump",

        "resultspath"       => "results",
		"configpreset"		=> "300",
		"history"			=> "added by kodell, January 22, 2013, for 3.0",
		"runloop"			=> "50000",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,480,481,482], 1, [600, 601, 602], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	54000 => {
		"id"				=> "54000",
		"name"				=> "MPEG4HD1080i-MPEG4HD1080i",
		"narrative"			=> "MPEG4HD1080i-MPEG4HD1080i of a Starz West HD AVCD-3.0 MPEG4 stream.",
        #"srcfile"           => "starzfamilyhd-apr4-1-source-recap.dump", #"starz-west-hd-avcd3.0-1.dump",
        "srcfile"           => "starz-e-hd-moneyball-1.dump",

        "resultspath"       => "results",
		"configpreset"		=> "300",
		"history"			=> "added by kodell, January 22, 2013, for 3.0",
		"runloop"			=> "3000",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,480,481,482], 1, [], 1)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	55000 => {
		"id"				=> "55000",
		"name"				=> "MPEG2HD720p-MPEG4SD480p",
		"narrative"			=> "MPEG2HD720p-MPEG4SD480p down-convert of a captured stream.",
        "srcfile"           => "fox-deportes-720p-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "205",
		"history"			=> "added by kodell, January 30, 2013, for 3.0",
		"runloop"			=> "10000",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                'validateEgress', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,480,481,482], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	56000 => {
		"id"				=> "56000",
		"name"				=> "MPEG4SD480p-MPEG2SD480p",
		"narrative"			=> "MPEG4SD480p-MPEG2SD480p encode of a captured stream.",
        "srcfile"           => "military-sd-mpeg4-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "400",
		"history"			=> "added by kodell, January 30, 2013, for 3.0",
		"runloop"			=> "10000",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                'validateEgress', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,480,481,482], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	56010 => {
		"id"				=> "56010",
		"name"				=> "MPEG4SD480p-MPEG2SD480p",
		"narrative"			=> "MPEG4SD480p-MPEG2SD480p encode - no source stream provided.",
        "resultspath"       => "results",
		"configpreset"		=> "400",
		"history"			=> "added by kodell, January 30, 2013, for 3.0",
		"runloop"			=> "50",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #'validateEgress', 
                                #['validateEgress', 10], 
                                #['egressContainsPids', ([0,480,481,482], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	56020 => {
		"id"				=> "56020",
		"name"				=> "MPEG4SD480p-MPEG2SD480p",
		"narrative"			=> "MPEG4SD480p-MPEG2SD480p encode - lossy ingress stream.",
        "resultspath"       => "results",
		"configpreset"		=> "400",
		"history"			=> "added by kodell, January 30, 2013, for 3.0",
		"runloop"			=> "10",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #'validateEgress', 
                                #['validateEgress', 10], 
                                #['egressContainsPids', ([0,480,481,482], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	56030 => {
		"id"				=> "56030",
		"name"				=> "MPEG4SD480p-MPEG2SD480p",
		"narrative"			=> "MPEG4SD480p-MPEG2SD480p encode - program change.",
        "resultspath"       => "results",
		"configpreset"		=> "400",
		"history"			=> "added by kodell, January 30, 2013, for 3.0",
		"runloop"			=> "20",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #'validateEgress', 
                                #['validateEgress', 10], 
                                #['egressContainsPids', ([0,480,481,482], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	56040 => {
		"id"				=> "56040",
		"name"				=> "MPEG4SD480p-MPEG2SD480p manual config",
		"narrative"			=> "MPEG4SD480p-MPEG2SD480p manual config.",
        "resultspath"       => "results",
		"configpreset"		=> "410",
		"history"			=> "added by kodell, March 13, 2013, for 3.0",
		"runloop"			=> "30",
        "srcfile"           => "military-sd-mpeg4-1.dump",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #'validateEgress', 
                                #['validateEgress', 10], 
                                #['egressContainsPids', ([0,480,481,482], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    57000 => {
		"id"				=> "57000",
		"name"				=> "MPEG2SD480p-MPEG4SD480p",
		"narrative"			=> "MPEG2SD480p-MPEG4SD480p, 192k audio passthrough, custom ES pid mapping. Verifies the ability of avcd-3.0 to remap pids on a custom basis.",
        #"srcfile"           => "food-sd-mpeg2.dump", 
        #"srcfile"           => "foxnews-mpeg2-1.dump",

        "resultspath"       => "results",
		"configpreset"		=> "500",
		"history"			=> "added by kodell, February 19, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    57010 => {
		"id"				=> "57010",
		"name"				=> "MPEG2SD480p-MPEG4SD480p",
		"narrative"			=> "MPEG2SD480p-MPEG4SD480p, 384k audio passthrough, custom ES pid mapping. Verifies the ability of avcd-3.0 to remap pids on a custom basis.",
        #"srcfile"           => "food-sd-mpeg2.dump", 
        #"srcfile"           => "foxnews-mpeg2-1.dump",

        "resultspath"       => "results",
		"configpreset"		=> "510",
		"history"			=> "added by kodell, February 19, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],#'startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
         #                       ['validateEgress', 10], 
         #                       ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    57020 => {
		"id"				=> "57020",
		"name"				=> "MPEG2HD720p-MPEG4SD480p, manual settings",
		"narrative"			=> "MPEG2HD720p-MPEG4SD480p",
        "srcfile"           => "fox-deportes-720p-1.dump",

        #"srcfile"           => "fox-deportes-720p-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "520",
		"history"			=> "added by kodell, March 8, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
         #                       ['validateEgress', 10], 
         #                       ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58000 => {
		"id"				=> "58000",
		"name"				=> "MPEG2HD720p-MPEG4SD480p, with auto-hook-on ability",
		"narrative"			=> "MPEG2HD720p-MPEG4SD480p, tests auto-hook-on functionality, 720p source.",
        #"srcfile"           => "a_e_hd-90s-mpeg2.1251236635.dump",
        "srcfile"           => "fox-deportes-720p-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "580",
		"history"			=> "added by kodell, March 8, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
         #                       ['validateEgress', 10], 
         #                       ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58010 => {
		"id"				=> "58010",
		"name"				=> "MPEG2HD720p-MPEG4HD720p, with auto-hook-on ability",
		"narrative"			=> "MPEG2HD720p-MPEG4HD720p, tests auto-hook-on functionality, 720p source.",
        #"srcfile"           => "a_e_hd-90s-mpeg2.1251236635.dump",
        "srcfile"           => "fox-deportes-720p-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "600",
		"history"			=> "added by kodell, March 12, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
         #                       ['validateEgress', 10], 
         #                       ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58020 => {
		"id"				=> "58020",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, with auto-hook-on ability",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i, tests auto-hook-on functionality, 1080i source.",
        #"srcfile"           => "nbc-sports-1.dump",
        "srcfile"           => "hgtv-source-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "590",
		"history"			=> "added by kodell, March 12, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58025 => {
		"id"				=> "58025",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, with auto-hook-on ability with a bad NBC-Sports HD pcap",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i, tests auto-hook-on functionality, 1080i source.",
        "srcfile"           => "nbc-sports-hd-bad-stream-2.dump",
        "resultspath"       => "results",
		"configpreset"		=> "590",
		"history"			=> "added by kodell, April 30, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['egressContains', ("AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58030 => {
		"id"				=> "58030",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, no src stream, with auto-hook-on ability",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i, tests auto-hook-on functionality, 1080i source.",
        #"srcfile"           => "nbc-sports-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "590",
		"history"			=> "added by kodell, March 12, 2013, for 3.0",
		"runloop"			=> "9000",
        "wantedegresses"	=> "h264,ac3",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateIngress', 2], 
                                'ingressContains',
                                'exposePmt',
                                #'analyzeConf'
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191] )],
                                ['egressContains', ("AC-3", "AVC")],
                                #['egressContains', ("AC-3", "AVC", "4:3", "16:9")],
                                #'exposePmt',
                                #'validateH264',
                                #['checkMdiDf', 3],
                                #                          ['validateEgress', 10], 
       #                         ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
        #                        ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58031 => {
		"id"				=> "58031",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, auto-hook-on, SAP",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i, tests auto-hook-on functionality, 1080i source, SAP.",
        "srcfile"           => "starz-e-hd-moneyball-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "591",
		"history"			=> "added by kodell, March 12, 2013, for 3.0",
		"runloop"			=> "9000",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,3001,8191], 0, [], 10)],
                                ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58032 => {
		"id"				=> "58032",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, auto-hook-on, SAP, no src",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i, tests auto-hook-on functionality, 1080i source, SAP.",
        "resultspath"       => "results",
		"configpreset"		=> "591",
		"history"			=> "added by kodell, March 12, 2013, for 3.0",
		"runloop"			=> "9000",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,3001,8191], 0, [], 10)],
                                ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},



    58035 => {
		"id"				=> "58035",
		"name"				=> "MPEG2HD1080i-MPEG4HD480p with auto-hook-on ability",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD480p with auto-hook-on",
        "srcfile"           => "universal-hd-src-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "605",
		"history"			=> "added by kodell, April 10, 2013, for 3.0",
		"runloop"			=> "30",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['egressContains', ("AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

    58037 => {
		"id"				=> "58037",
		"name"				=> "MPEG2SD480p-MPEG4SD480p, with auto-hook-on ability, SCTE-35 source",
		"narrative"			=> "MPEG2SD480p-MPEG4SD480p, tests auto-hook-on functionality, 480p source.",
        "resultspath"       => "results",
		"configpreset"		=> "580",
        "srcfile"           => "food-sd-mpeg2.dump",
		"history"			=> "added by kodell, April 23 2013, for 3.0",
		"runloop"			=> "40",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateIngress', 2], 
                                'ingressContains',
                                'exposePmt',
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [800], 10)],
                                #['egressContains', ("AC-3", "AVC")],
                                ],
		"postrunactions" 	=> ['stopAvcd'],
		#"postrunactions" 	=> ['stopAvcd', ['egressContainedScte35', (800)] ],
	},
    58040 => {
		"id"				=> "58040",
		"name"				=> "MPEG2SD480p-MPEG4SD480p, with auto-hook-on ability, no source stream",
		"narrative"			=> "MPEG2SD480p-MPEG4SD480p, tests auto-hook-on functionality, 480p source.",
        "resultspath"       => "results",
		"configpreset"		=> "580",
		"history"			=> "added by kodell, March 25, 2013, for 3.0",
		"runloop"			=> "100",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                #['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                #['egressContains', ("AC-3", "AVC")],
                                #['checkMdiDf', 10],
                                'validateH264',
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58050 => {
		"id"				=> "58050",
		"name"				=> "MPEG2SD480p-MPEG4SD480p, HBO SD, with auto-hook-on ability",
		"narrative"			=> "MPEG2SD480p-MPEG4SD480p, tests auto-hook-on functionality, 480p HBO source.",
        "resultspath"       => "results",
		"configpreset"		=> "580",
		"history"			=> "added by kodell, April 3, 2013, for 3.0",
		"runloop"			=> "10",
        "srcfile"           => "MPEGPCAP-3600seconds-3mbps-hboe.dump",
		"prerunactions"		=> [],
        #'startStream', 
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['egressContains', ("AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58060 => {
		"id"				=> "58060",
		"name"				=> "MPEG2SD480p-MPEG4SD480p, HBO SD, with auto-hook-on ability, SAP with fixed PIDs",
		"narrative"			=> "MPEG2SD480p-MPEG4SD480p, tests auto-hook-on functionality, 480p HBO source.",
        "resultspath"       => "results",
		"configpreset"		=> "597",
		"history"			=> "added by kodell, April 15, 2013, for 3.0",
		"runloop"			=> "20",
        "srcfile"           => "MPEGPCAP-3600seconds-3mbps-hboe.dump",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,3001,8191], 0, [], 10)],
                                ['egressContains', ("AC-3AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58070 => {
		"id"				=> "58070",
		"name"				=> "MPEG2SD480p-MPEG4SD480p, HBO SD, with auto-hook-on ability, SAP",
		"narrative"			=> "MPEG2SD480p-MPEG4SD480p, tests auto-hook-on functionality, 480p HBO source.",
        "resultspath"       => "results",
		"configpreset"		=> "598",
		"history"			=> "added by kodell, April 15, 2013, for 3.0",
		"runloop"			=> "20",
        "srcfile"           => "MPEGPCAP-3600seconds-3mbps-hboe.dump",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,3001,8191], 0, [], 10)],
                                ['egressContains', ("AC-3AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

    58080 => {
		"id"				=> "58080",
		"name"				=> "MPEG2HD720p-MPEG4HD720p, with auto-hook-on ability, 448k audio",
		"narrative"			=> "MPEG2HD720p-MPEG4HD720p, tests auto-hook-on functionality, 720p source.",
        "srcfile"           => "espn-e-hd-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "600",
		"history"			=> "added by kodell, April 22, 2013, for 3.0",
		"runloop"			=> "10",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['egressContains', ("AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

    58090 => {
		"id"				=> "58090",
		"name"				=> "MPEG2HD720p-MPEG4SD480p, with auto-hook-on ability, ESPN 448k audio",
		"narrative"			=> "MPEG2HD720p-MPEG4SD480p, tests auto-hook-on functionality, 720p source.",
        "srcfile"           => "espn-e-hd-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "603",
		"history"			=> "added by kodell, April 22, 2013, for 3.0",
		"runloop"			=> "10",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['egressContains', ("AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

    58100 => {
		"id"				=> "58100",
		"name"				=> "MPEG2HD720p-MPEG4HD720p, with auto-hook-on ability, 448k audio, PCR rollover",
		"narrative"			=> "MPEG2HD720p-MPEG4HD720p, tests auto-hook-on functionality",
        "srcfile"           => "espn-pts-rollover.dump",
        "resultspath"       => "results",
		"configpreset"		=> "600",
		"history"			=> "added by kodell, April 22, 2013, for 3.0",
		"runloop"			=> "30",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['egressContains', ("AC-3", "AVC")],
                                ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58110 => {
		"id"				=> "58110",
		"name"			 	=> "MPEG2HD1440x1080i-MPEG4SD480p, with auto-hook-on ability, Gulfcom-ctv-e-hd",
		"narrative"			=> "Issue with maintaining correct SAR, DAR.",
        "srcfile"           => "gulfcom-ctv-e-hd.dump",
        "resultspath"       => "results",
		"configpreset"		=> "603",
        "wantedegresses"	=> "h264,ac3",
		"history"			=> "added by kodell, May 2, 2014, for 3.0",
		"runloop"			=> "30",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0)],
#                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['egressContains', ("AC-3", "AVC", "40:33", "4:3")],
                                ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58120 => {
		"id"				=> "58120",
		"name"			 	=> "MPEG2HD1440x1080i-MPEG4HD1080i, with auto-hook-on ability, Gulfcom-ctv-e-hd",
		"narrative"			=> "Issue with maintaining correct SAR, DAR.",
        "srcfile"           => "gulfcom-ctv-e-hd.dump",
        "resultspath"       => "results",
		"configpreset"		=> "590",
        "wantedegresses"	=> "h264,ac3",
		"history"			=> "added by kodell, May 2, 2014, for 3.0",
		"runloop"			=> "30",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0)],
#                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['egressContains', ("AC-3", "AVC", "4:3", "16:9")],
                                ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

    58200 => {
		"id"				=> "58200",
		"name"				=> "MPEG4SD480p-MPEG2SD480p, with auto-hook-on ability",
		"narrative"			=> "MPEG4SD480p-MPEG2SD480p, tests auto-hook-on functionality, 480p source.",
        "srcfile"           => "food-sd-mpeg2.dump", 
        "resultspath"       => "results",
		"configpreset"		=> "700",
		"history"			=> "added by kodell, March 12, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
         #                       ['validateEgress', 10], 
         #                       ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                          ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    58300 => {
		"id"				=> "58300",
		"name"				=> "MPEG4SD480p-MPEG2SD480p, with auto-hook-on ability",
		"narrative"			=> "MPEG4SD480p-MPEG2SD480p, tests auto-hook-on functionality, no source.",
        "resultspath"       => "results",
		"configpreset"		=> "700",
		"history"			=> "added by kodell, March 12, 2013, for 3.0",
		"runloop"			=> "150",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
         #                       ['validateEgress', 10], 
         #                       ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                          ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

    68030 => {
		"id"				=> "68030",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, no src stream, with auto-hook-on ability, SAP/PIP",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i, tests auto-hook-on functionality, 1080i source.",
        "resultspath"       => "results",
		"configpreset"		=> "890",
		"history"			=> "added by kodell, May 22, 2013, for 3.0",
		"runloop"			=> "9000",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #'analyzeConf'
                                ['validateIngress', 2], 
                                'ingressContains',
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [800], 10)],
                                ['validateMux', (10)],
                                'validateH264',
                                ['validateEgress', 10, "234.1.1.12"], 
                                ['egressContainsPids', ([0,1000,2000,8191], 0, [], 0)],
                                ['validateMux', (10, "pip")],
                                'validateH264',
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    68040 => {
		"id"				=> "68040",
		"name"				=> "MPEG2SD480p-MPEG4SD480p, auto-hook-on, PIP, SAP, no source stream",
		"narrative"			=> "MPEG2SD480p-MPEG4SD480p, tests auto-hook-on functionality, 480p source.",
        "resultspath"       => "results",
		"configpreset"		=> "580",
		"history"			=> "added by kodell, March 25, 2013, for 3.0",
		"runloop"			=> "100",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,3001,8191], 0, [], 10)],
                                ['egressContains', ("AC-3AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    68050 => {
		"id"				=> "68050",
		"name"				=> "MPEG2HD720p-MPEG4HD720p, no src stream, with auto-hook-on ability, SAP/PIP",
		"narrative"			=> "MPEG2HD720p-MPEG4HD720p, tests auto-hook-on functionality, 720p source.",
        "resultspath"       => "results",
		"configpreset"		=> "900",
		"history"			=> "added by kodell, June 24, 2013, for 3.1",
		"runloop"			=> "9000",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #'analyzeConf'
                                ['validateIngress', 2], 
                                'ingressContains',
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                #['egressContains', ("", "AVC")],
                                ['validateMux', (10)],
                                'validateH264',
                                ['validateEgress', 10, "234.1.1.12"], 
                                ['egressContainsPids', ([0,1000,2000], 0, [], 0)],
                                #['egressContains', ("", "AVC")],
                                ['validateMux', (10, "pip")],
                                'validateH264',
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	70000 => {
		"id"				=> "70000",
		"name"				=> "MPEG2HD720p-MPEG4HD720p, bad configuration",
		"narrative"			=> "MPEG2HD720p-MPEG4HD720p of a captured stream, with a known bad configuration",
        "srcfile"           => "nat_geo_hd-90s-mpeg2.1251236815.dump",
        "resultspath"       => "results",
		"configpreset"		=> "201",
		"history"			=> "added by kodell, January 17, 2013, for 3.0",
		"runloop"			=> "1000",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #'validateEgress', 
                                #['egressContainsPids', ([0,480,481,482])],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
    },


    70100 => {
		"id"				=> "70100",
		"name"				=> "MPEG4HD1080i-MPEG4HD1080i with custom ES pids",
		"narrative"			=> "MPEG4HD1080i-MPEG4HD1080i, custom ES pid mapping. Verifies the ability of avcd-3.0 to remap pids on a custom basis.",
        "srcfile"           => "starzfamilyhd-apr4-1-source-recap.dump", 

        "resultspath"       => "results",
		"configpreset"		=> "301",
		"history"			=> "added by kodell, January 29, 2013, for 3.0",
		"runloop"			=> "50000",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> ['startStream'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,32,2000,3000], 1, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

    90000 => {
	"id"               => "90000",
	"name"	           => "MPEG41080i-MPEG41080i soak (extended run) test.",
	"narrative"        => "A long term, 48-72 hour soak test that monitors for memory history, bitrate, ES pids, etc.",
	"teststeps"        => [("Run test \#210140 with iterations at 20000. During different sampling points, view/listen to the egress via STB and TV. Check items such as MDI-DF, bitrate, SCTE-35 passthrough near typical ad insertion points (20m before the top of the hour).",
                        )],
	"history"          => "added by kodell, March 18, 2013 for avcd-3.0.0",
	"prerunactions"    => [],
	"startactions"	   => [],
	"runactions"       => ['manualTest'],
	"postrunactions"   => [],
    },
    
    90010 => {
        "id"               => "90010",
        "name"	           => "PCR rollover, MPEG41080i-MPEG41080i test.",
        "narrative"        => "A soak test to test survival of scr-based PCR-rollover events. A stream is used that will exhibit a PCR rollover, then proper stream timing, performance is checked after the event has occured.",
        "teststeps"        => [("Run one of the \#210000 tests that the source stream will soon experience a rollover event. After the rollover, avcd.log should report\n\tINFO PCR rollover detected and A/V playback should be good.",
                               )],
        "history"          => "added by kodell, March 20, 2013 for avcd-3.0.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },

    90020 => {
		"id"				=> "90020",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, repeated start/stop ingress stream",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i, tests auto-hook-on functionality, 1080i source.",
        "srcfile"           => "hgtv-source-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "590",
		"history"			=> "added by kodell, April 26, 2013, for 3.0",
		"runloop"			=> "100",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['pause',(45)],
                                'stopStream',
                                ['pause',(95)],
                                'startStream', 
                                ['pause',(15)],
                                ['validateEgress', 10], 
         #                       ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    90030 => {
		"id"				=> "90030",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, loss if source ingress for 1m",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i, auto-hook-on, source contains no ingress for 1m.",
        "srcfile"           => "versus-holed.dump",
        "resultspath"       => "results",
		"configpreset"		=> "590",
		"history"			=> "added by kodell, April 26, 2013, for 3.0",
		"runloop"			=> "100",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    90040 => {
		"id"				=> "90040",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, Lifetime HD, stereo audio es listed first in PMT.",
		"narrative"			=> "As of 3.1.0.45882, avcd should automatically egress the highest bitrate, English audio ES.",
        "srcfile"           => "lifetime-movie-hd-2m.dump",
        "resultspath"       => "results",
		"configpreset"		=> "590",
		"history"			=> "added by kodell, June 13, 2013, for 3.1",
		"runloop"			=> "100",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191] )],
                                ['egressContains', ("AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    90050 => {
		"id"				=> "90050",
		"name"				=> "MPEG2SD480p-MPEG4SD480p, src audio change from 192k to 384k",
		"narrative"			=> "As of 3.1.0.45882, avcd should automatically adjust the video bitrate to allow for the larger bitrate audio ES. Querying the running API should show the change in mux-audio-bitrate.",
        "resultspath"       => "results",
		"configpreset"		=> "580",
		"history"			=> "added by kodell, June 13, 2013, for 3.1",
		"runloop"			=> "100",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
                                #['egressContains', ("AC-3", "AVC")],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

    90060 => {
		"id"				=> "90060",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, soak test",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i",
        "resultspath"       => "results",
		"configpreset"		=> "590",
		"history"			=> "added by kodell, June 21, 2013 for 3.1",
		"runloop"			=> "9000",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateIngress', 2], 
                                'ingressContains',
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000,8191] )],
                                ['egressContains', ("AC-3", "AVC")],
                                'validateH264',
      #                          ['validateEgress', 10], 
       #                         ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
        #                        ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    90070 => {
		"id"				=> "90070",
		"name"				=> "Fixed audio pids",
		"narrative"			=> "Take the infamous Big Mama HBO clip and remap SPA audio to primary, ENG audio to secondary via fixed audio pids.",
        "resultspath"       => "results",
        "wantedegresses"	=> "", # note these are set depending on the source ESes, where?
		"configpreset"		=> "582",
		"history"			=> "added by kodell, July 9, 2013 for 3.1",
        "srcfile"           => "MPEGPCAP-3600seconds-3mbps-hboe.dump",
		"runloop"			=> "10",
		"prerunactions"		=> [],
		"startactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateIngress', 2], 
                                'ingressContains',
                                ['validateEgress', 10], 
                                ['egressContainsPids', ( [0,1000,2000,3000,3001,8191], 0, ([]), 0 )], # set wanted pids dynamically
                                #['egressContains', ("AC-3", "AVC")],
                                'validateH264',
      #                          ['validateEgress', 10], 
       #                         ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
        #                        ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    99000 => {
		"id"				=> "99000",
		"name"				=> "MPEG2HD1080i-MPEG4HD1080i, no src stream, with auto-hook-on ability",
		"narrative"			=> "MPEG2HD1080i-MPEG4HD1080i, tests auto-hook-on functionality, 1080i source.",
        #"srcfile"           => "nbc-sports-1.dump",
        "resultspath"       => "results",
		"configpreset"		=> "99000",
		"history"			=> "added by kodell, March 12, 2013, for 3.0",
		"runloop"			=> "9000",
		"prerunactions"		=> [],
		"startactions"		=> ['startAvcd', 'createConfig'],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #'analyzeConf'
      #                          ['validateEgress', 10], 
       #                         ['egressContainsPids', ([0,1000,2000,3000,8191], 0, [], 10)],
        #                        ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    100000 => {
	"id"               => "100000",
	"name"	           => "Manual: Lossy multicast ingress.",
	"narrative"        => "This test purposefully introduces packet loss on the AVCD ingress to validate AVCD's ability to handle the degradation and recovery once the degradation halts.",
	"teststeps"        => [("Setup QA-tool multi-streams to produce a good, then packet-loss, then good multicast stream.\n\tEx. multi-streams 234.1.1.1 9.\n\tRun any of the multicast tests, ex. 51000, and let the test proceed as normal. After 15s or so, start the ingress degradation by issuing the following command.\n\tkillall -SIGUSR1 multi-streams.\nThe egress of AVCD when watched via display will exhibit macro-blocking, loss of audio etc. Halt the ingress degadation by issuing\n\tkillall -SIGUSR2 multi-streams. After 5-10s, the AVCD egress should resume and play normally on display. Did the AVCD egress recover?",
                        )],
	"history"          => "added by kodell, November 27 2012, for avcd-3.0.0",
	"prerunactions"    => [],
	"startactions"	   => [],
	"runactions"       => ['manualTest'],
	"postrunactions"   => [],
},
    100010 => {
        "id"               => "100010",
        "name"	           => "Manual: Source stream rollover.",
        "narrative"        => "This test purposefully introduces a source stream rollover where the source stream is looped over and over. AVCD should recover after the rollover with no memory loss or a/v issues.",
        "teststeps"        => [("Run the multicast test \#51000 with a runloop of 30 (--test-params=runloop=30). 30s in the source stream will loopover. Watch AVCD's egress via display and ts_tool.pl. The a/v should recover within 5s of loopover. Did the AVCD egress recover?",
                               )],
        "history"          => "added by kodell, November 27 2012, for avcd-3.0.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100012 => {
        "id"               => "100012",
        "name"	           => "Manual: Source stream rollover - CSPAN3.",
        "narrative"        => "This test purposefully introduces a source stream rollover where the source stream is looped over and over. AVCD should recover after the rollover with no memory loss or a/v issues.",
        "teststeps"        => [("Run the multicast test \#51000 with a runloop of 30 (--test-params=runloop=30). 30s in the source stream will loopover. Watch AVCD's egress via display and ts_tool.pl. The a/v should recover within 5s of loopover. Did the AVCD egress recover?",
                               )],
        "history"          => "added by kodell, September 2 2015, for avcd-3.2.8",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100020 => {
        "id"               => "100020",
        "name"	           => "Manual: Lost source ingress for 2m",
        "narrative"        => "This test purposefully introduces a source stream loss for 2m, then resumes the source stream. AVCD should recover after the source stream resumption with no memory gain or a/v issues.",
        "teststeps"        => [("Run the multicast test \#58030. Start the Versus HD, 1 hour PCAP capture. Let Avcd egress then take away the tcpplay playback for 2m. Resume the tcpplay playback. Does avcd recover within 30s?",
                               )],
        "history"          => "added by kodell, May 2, 2012, for avcd-3.0.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100030 => {
        "id"               => "100030",
        "name"	           => "Manual: soft restart of avcd encode",
        "narrative"        => "Exercise the API-based soft restart mechanism of avcd.",
        "teststeps"        => [("Start an encode. Tail the log and then via 'telnet localhost <CC port of avcd>' issue a 'restart' Examine the logging to see the restart take effect, verify encoder egress and process health stabilizes after the operation.",
                                "Verify that speed_control returns to normal operation. Issue via telnet, 'SET:LOG_SPEED_CONTROL=1;NAME=encoder' and review the log. Should appear similar to:\n2014-09-11 14:31:10 codec_x264.c:539 INFO speed control:NDX=0,speed=10.02 10[0.74812],t/c/w= 31244/     0/ 34067 0.0000,fps=29.35",
                                "verify that ingress CC_ERRs are reset to zero"
                               )],
        "history"          => "added by kodell, Sep 11, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100040 => {
        "id"               => "100040",
        "name"	           => "Manual: verify cc-error detection on ingress",
        "narrative"        => "Review the detection of cc-errors on ingress.",
        "teststeps"        => [("Start an encode. Tail the log and then purposefully introduce cc-errors into the ingress via various means. These should be logged.",
                               )],
        "history"          => "added by kodell, Sep 11, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100050 => {
	"id"               => "100050",
	"name"	           => "Manual: Ingress CC_ERR logging.",
	"narrative"        => "As of 3.2.1, avcd now monitors the SPTS's ES for CC errors.",
	"teststeps"        => [("Setup QA-tool multi-streams to produce a good, then packet-loss, then good multicast stream.\n\tEx. multi-streams 234.1.1.1 9.\n\tRun any of the multicast tests, ex. 51000, and let the test proceed as normal. After 15s or so, tail the avcd.log and look for CC_ERR stats on the ingress, they should be zero.",
                            "then, kill and restart the multi-streams process, this will cause a known, limited CC error condition on the ingress to avcd. Tail the log again and you should see the CC_ERR stat increment as in the ingress had the discontinuity.",
                        )],
	"history"          => "added by kodell, September 25 2014, for avcd-3.2.1",
	"prerunactions"    => [],
	"startactions"	   => [],
	"runactions"       => ['manualTest'],
	"postrunactions"   => [],
    },
    100060 => {
        "id"               => "100060",
        "name"	           => "Manual: validate channel context is logged.",
        "narrative"        => "As of 3.2.2, avcd now logs this information..",
        "teststeps"        => [("start avcd with context set, verify in log."
                               )],
        "history"          => "added by kodell, September 26 2014, for avcd-3.2.2",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100100 => {
        "id"               => "100100",
        "name"	           => "Manual: verify SNMP level setting",
        "narrative"        => "validates this API controllled functionality.",
        "teststeps"        => [("With a avcd running, telnet localhost <C&C port> and issue 'get:type=snmp_level', should receive similar 'OK:SNMP_LEVEL=0'.",
                                "Then set level to '1' with by telneting and issuing 'snmp_level:val=1, should receive 'OK:SNMP_LEVEL=1'.",
                                "Verify log messaging records the API transactions."
                               )],
        "history"          => "added by kodell, Sep 15, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100110 => {
        "id"               => "100110",
        "name"	           => "Manual: exercise all allowed and some non-allowed values to SNMP API",
        "narrative"        => "validates this API controllled functionality.",
        "teststeps"        => [("via script, set snmp_levels to invalid and then valid values.'.",
                                "Verify log messaging records the API transactions.",
                                "Verify AVCD continues to function normally afterward."
                               )],
        "history"          => "added by kodell, Sep 15, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100120 => {
        "id"               => "100120",
        "name"	           => "Manual: validate absent -H host:port functionality",
        "narrative"        => "validates that avcd starts and sends snmp traps to loclahost:162",
        "teststeps"        => [("start avcd, enable snmptrapd and watch for localhost messaging to arrive",
                               )],
        "history"          => "added by kodell, Sep 15, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100130 => {
        "id"               => "100130",
        "name"	           => "Manual: validate snmp_host add:remove functionality",
        "narrative"        => "validates that this functionality works as intended and that snmp trapping commences when a new host is added",
        "teststeps"        => [("start avcd, enable snmptrapd. Issue a remove via telnet localhost <C&C port> then 'snmp_host:remove=127.0.0.1:162'",
                                "Issue an add back the host with 'snmp_host:val=127.0.0.1:262",
                                "avcd log messaging should log both events, snmp logging should record any future snmp traps",
                               )],
        "history"          => "added by kodell, Sep 16, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100140 => {
        "id"               => "100140",
        "name"	           => "Manual: validate multiple snmp hosts",
        "narrative"        => "validates that multiple snmp hosts/traps receive snmp messaging",
        "teststeps"        => [("start avcd, add another snmp_host via telnet localhost <C&C port> then 'snmp_host:val=10.16.3.220:162'",
                                "introduce ingress discontinuity or other to trigger a snmp message. Verify the message arrives both at the localhost trap and remote (10.16.3.220) trap",
                               )],
        "history"          => "added by kodell, Sep 16, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100200 => {
        "id"               => "100200",
        "name"	           => "Manual: verify SNMP traps",
        "narrative"        => "validates monitoring functionality.",
        "teststeps"        => [("With a avcd running, purposefully introduce ingress packet loss, other anomalies for avcd to process.",
                                "Verify snmp log messaging records the events."
                               )],
        "history"          => "added by kodell, Sep 15, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100210 => {
        "id"               => "100210",
        "name"	           => "Manual: verify SNMP traps to a remote server",
        "narrative"        => "validates monitoring functionality.",
        "teststeps"        => [("Run avcd with the the -H host:port param. Monitor the snmp logging on the remote host for incoming snmp messages.",
                               )],
        "history"          => "added by kodell, Sep 15, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100220 => {
        "id"               => "100220",
        "name"	           => "Manual: verify disabling, then enabling SNMP traps",
        "narrative"        => "as described",
        "teststeps"        => [("start avcd, then via API disable SNMP trapping, then re-enable. snmp logging should halt when disabled, then resume when enabled.",
                               )],
        "history"          => "added by kodell, Sep 15, 2014, for avcd-3.2.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100230 => {
        "id"               => "100230",
        "name"	           => "Manual: if not SNMP host in /etc/hosts, avcd should fail startup",
        "narrative"        => "as described",
        "teststeps"        => [("ensure 'snmphost' is not defined in /etc/hosts. start avcd, log messaging should report why avcd failed to start.",
                               )],
        "history"          => "added by kodell, Sep 22, 2014, for avcd-3.2.1",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100500 => {
        "id"               => "100500",
        "name"	           => "Manual: SNMP level at 3",
        "narrative"        => "should trap only CRITICAL log entries",
        "teststeps"        => [("set snmp_level to 3. Induce lossy ingress. Only CRITICAL-level messages should appear in /var/log/snmptrapd.log",
                               )],
        "history"          => "added by kodell, Sep 24, 2014, for avcd-3.2.1",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100510 => {
        "id"               => "100510",
        "name"	           => "Manual: SNMP level at 2",
        "narrative"        => "should trap only ERROR, CRITICAL log entries",
        "teststeps"        => [("set snmp_level to 2. Induce lossy ingress. Only ERROR, CRITICAL-level messages should appear in /var/log/snmptrapd.log",
                               )],
        "history"          => "added by kodell, Sep 24, 2014, for avcd-3.2.1",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100520 => {
        "id"               => "100520",
        "name"	           => "Manual: SNMP level at 1",
        "narrative"        => "should trap only WARN/NOTICE, ERROR, CRITICAL log entries",
        "teststeps"        => [("set snmp_level to 1. Induce lossy ingress. Only WARN/NOTICE, ERROR, CRITICAL-level messages should appear in /var/log/snmptrapd.log",
                               )],
        "history"          => "added by kodell, Sep 24, 2014, for avcd-3.2.1",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100530 => {
        "id"               => "100530",
        "name"	           => "Manual: SNMP level at 0",
        "narrative"        => "should trap all DEBUG/INFO, WARN/NOTICE, ERROR, CRITICAL log entries",
        "teststeps"        => [("set snmp_level to 0. Induce lossy ingress. All DEBUG/INFO, WARN/NOTICE, ERROR, CRITICAL-level messages should appear in /var/log/snmptrapd.log",
                               )],
        "history"          => "added by kodell, Sep 24, 2014, for avcd-3.2.1",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },
    100600 => {
        "id"               => "100600",
        "name"	           => "Manual: Drift: Verify drift/timing adjustments as of 3.2.4",
        "narrative"        => "",
        "teststeps"        => [("Monitor drift stats from log. Verify pcr-bitrate, jitter, mdi-df, UDP bitrate.",
                               )],
        "history"          => "added by kodell, April 30, 2015, for avcd-3.2.4",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },

    110000 => {
        "id"               => "110000",
        "name"	           => "Manual: Visual comparison of avcd-2.11 and avcd-3.0 at 5.5 Mbps, 1080i AVC encode.",
        "narrative"        => "This test produces two 1080i video frames for manual, visual comparison.",
        "teststeps"        => [("Run test \#53000 which will produce avcd-3.0 output on the user specified egress address. Configure an avcd-2.11 encode of the same ingress stream on a different encoder. Watch both engresses on STB/TV. Record 15s of high motion frames with ts_tool on both egress streams. Use mplayer to bring up both streams and using the '.' key take both streams to the worst 3.0 visual frame seen. Take a screensnapshot with scrot or other. Is the avcd-3.0 frame better visually that the 2.11 frame?",
                               )],
        "history"          => "added by kodell, January 31, for avcd-3.0.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },	

    110100 => {
        "id"               => "110100",
        "name"	           => "Manual: Start twelve (12) MPEG2SD-MPEG4SD encodes. Monitor individual streams, server loads, etc. while some external load is placed on server.",
        "narrative"        => "This test starts twelve (12) MPEG2SD-MPEG4SD encodes. MDI-DF, CBR, stream integrity checked.",
        "teststeps"        => [("Start twelve encodes using testmultiple.pl or other tool. Monitor the egress streams with ts_tool in multiple stream mode. Ensure all twelve encodes successfully started.", 
                                "Using ts_tool, check the MDI-DF of each stream, each should spec out at 9-50ms.",
                                "Using ts_tool, check the UDP bitrate of each stream, each should remain a constant bitrate."
                               )],
        "history"          => "added by kodell, January 31, for avcd-3.0.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },	
    110200 => {
        "id"               => "110200",
        "name"	           => "Manual: Verify PCR insertion rate.",
        "narrative"        => "As of July 2015 we've changed the default PCR insertion rate to 25 ms.",
        "teststeps"        => [("Start an encode. Verify pcr insertion rate via ts_tool or other..", 
                               )],
        "history"          => "added by kodell, June 15-2015, for avcd-3.2.5",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },	
    110210 => {
        "id"               => "110210",
        "name"	           => "Manual: Verify PCR insertion rate of PIPs.",
        "narrative"        => "As of July 2015 we've changed the default PCR insertion rate to 25 ms for main profiles.",
        "teststeps"        => [("Start an encode. Verify pcr insertion rate via ts_tool or other..", 
                               )],
        "history"          => "added by kodell, Aug 11-2015, for avcd-3.2.6",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },	
    110300 => {
        "id"               => "110300",
        "name"	           => "Manual: Verify mux-audio-maxdelay change of 3.2.7.",
        "narrative"        => "As of August 2015 we've changed the mux-audio-maxdelay to 0.060 for main profiles.",
        "teststeps"        => [("Start an encode. Verify mux-audio-maxdelay", 
                               )],
        "history"          => "added by kodell, Aug 24-2015, for avcd-3.2.7",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },	
    110400 => {
        "id"               => "110400",
        "name"	           => "Manual: Verify x264--vbv-bufsize setting change for SD and HD profiles.",
        "narrative"        => "As of August 31 2015 we've changed this setting to 3147 down from 5400 for the HD profile.",
        "teststeps"        => [("Start an encode. Verify correct speed control behavior, video quality, etc.", 
                               )],
        "history"          => "added by kodell, Aug 31-2015, for avcd-3.2.8",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },	
    110500 => {
        "id"               => "110500",
        "name"	           => "Manual: Verify pts-pts/dts-dts deltas for soft-telecined source content encoding.",
        "narrative"        => "As of September 2015 we have tweaked the deinterlace filter to only deinterlace frames with the interlaced flag(s) set. This means no more automatic instantiation the deinterlace filter - it's always instantiated.",
        "teststeps"        => [("Using ts_check run: \'ts_check -i capture-2.ts -n ts | grep \": 2000\" | ts_check.pl --check=\'pts-pts\'\' Deltas should oscillate between 3003/4504-5", 
                               )],
        "history"          => "added by kodell, Sep 14 2015, for avcd-3.2.9",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],
        "postrunactions"   => [],
    },	

    
	200000 => {
		"id"				=> "200000",
		"name"				=> "BSHE[static conf]",
		"narrative"			=> "Cycle through HD channels involved in the BSHE HD transponder reduction effort.",
        "resultspath"       => "results",
		"channelset"		=> [(
                                )],
		"configpreset"		=> "",
		"history"			=> "added by kodell, February 21, 2013, for 3.0",
		"runloop"			=> "720",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],
		"runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000], 0, [600, 601, 602], 10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
	210000 => {
		"id"				=> "210000",
		"name"				=> "BSHE[auto-hook-on conf]",
		"narrative"			=> "Cycle through HD channels involved in the BSHE HD transponder reduction effort, using auto-hookon technology.",
        "resultspath"       => "results",
		"channelset"		=> [(
                                )],
		"configpreset"		=> "",
		"history"			=> "added by kodell, February 21, 2013, for 3.0",
		"runloop"			=> "900",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],
        "runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000], 0, [], 0)],
                                ['egressContains', ("AC-3", "AVC")],
                                ['validateMux', (10)],
                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

	220000 => {
		"id"				=> "220000",
		"name"				=> "BSHE[auto-hook-on conf] SAP enabled",
		"narrative"			=> "Cycle through HD channels, SAP enabled.",
        "resultspath"       => "results",
		"channelset"		=> [(
                                )],
		"configpreset"		=> "",
		"history"			=> "added by kodell, May 20, 2013, for 3.0",
		"runloop"			=> "20",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],
        "runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #['scanIngress', 5],
                                ['validateIngress', 2], 
                                'ingressContains',
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([0,1000,2000,3000], 0, [], 0)],
                                ['egressContains', ("", "AVC")],
                                ['validateMux', (10)],
                                
                                ['validateEgress', 10, "127.1.1.11"], 
                                ['egressContainsPids', ([0,1000,2000], 0, [], 0)],
                                #['egressContains', ("none", "AVC")],
                                ['validateMux', (10), "pip"],

                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    
	230000 => {
		"id"				=> "230000",
		"name"				=> "BSHE[SD/HD SAP/PIP]",
		"narrative"			=> "Cycle through all SD/HD channels, SAP/PIP enabled.",
        "resultspath"       => "results",
		"channelset"		=> [(                                )],
        "configpreset"		=> "",
        "wantedegresses"	=> "", # note these are set depending on the source ESes, where?
        "history"			=> "added by kodell, June 18, 2013, for 3.1",
		"runloop"			=> "5",
		"prerunactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"startactions"		=> ['checkConfig'],
        "runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #['scanIngress', 15],
                                ['validateIngress', 2], 
                                'ingressContains',
                                ['validateEgress', 10], 
                                #['egressContainsPids', ((), 0, [800, 801,802], 200)], # set wanted pids dynamically
                                ['egressContains', ("AC-3", "AVC")],
                                ['validateMux', (10)],
                                #['checkMdiDf', (10)],
                                
                                ['validateEgress', 10, "234.1.1.82"], 
                                ['egressContainsPids', ([0,1000,2000,8191], 0, [], 0)],
                                #['egressContains', ("none", "AVC")],
                                ['validateMux', (10), "pip"],

                                ['pause',(5)] ],
		"postrunactions" 	=>  ['stopAvcd'],
	},

	240000 => {
		"id"				=> "240000",
		"name"				=> "BSHE[SD/HD SAP/PIP]",
		"narrative"			=> "Cycle through all SD/HD channels, SAP/PIP enabled.",
        "resultspath"       => "results",
		"channelset"		=> [(                                )],
        "configpreset"		=> "",
        "wantedegresses"	=> "", # note these are set depending on the source ESes, where?
        "history"			=> "added by kodell, July 2, 2013, for 3.1",
		"runloop"			=> "21",
		"prerunactions"		=> ['startAvcd', 'createConfig'],
		"startactions"		=> [],
        "runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #['scanIngress', 5],
                                ['validateIngress', 2], 
                                'ingressContains',
                                ['validateEgress', 10], 
                                ['egressContainsPids', ([], 0, ([800,801,802,803]), 2000)], # set wanted pids dynamically
                                ['egressContains', ("AC-3", "AVC")],
                                ['validateMux', (10)],
                                ['checkMdiDf', (10)],
                                
                                ['validateEgress', 10, "234.1.1.12"], 
                                ['egressContainsPids', ([0,1000,2000,8191], 0, [], 0)],
                                #['egressContains', ("none", "AVC")],
                                ['validateMux', (10), "pip"],

                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},
    
    250000 => {
		"id"				=> "250000",
		"name"				=> "BSHE[SD/HD SAP/PIP]",
		"narrative"			=> "Cycle through all sports SD/HD channels 2.5 bitrate",
        "resultspath"       => "results",
		"channelset"		=> [()],
        "configpreset"		=> "",
        "wantedegresses"	=> "",
        "history"			=> "added by brenton, July 17, 2013, for 3.1",
		"runloop"			=> "8",
		"prerunactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"startactions"		=> [],
        "runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                ['validateIngress', 2], 
                                'ingressContains',
                                ['validateEgress', 10], 
                                ['egressContains', ("AC-3", "AVC")],
                                ['validateMux', (10)],
                                ['validateEgress', 10, "234.1.1.82"], 
                                ['egressContainsPids', ([0,1000,2000,8191], 0, [], 0)],
                                ['validateMux', (10), "pip"],

                                ['pause',(5)] ],
		"postrunactions" 	=> ['stopAvcd'],
	},

	260000 => {
		"id"				=> "260000",
		"name"				=> "BSHE[SD DOWNCONVERT SAP/PIP]",
		"narrative"			=> "Cycle through all downconvert SD channels, SAP/PIP enabled.",
        "resultspath"       => "results",
		"channelset"		=> [(                                )],
        "configpreset"		=> "",
        "wantedegresses"	=> "", # note these are set depending on the source ESes, where?
        "history"			=> "added by kodell, Sep 24, 2015, for 3.2.10",
		"runloop"			=> "5",
		"prerunactions"		=> ['startStream', 'startAvcd', 'createConfig'],
		"startactions"		=> ['checkConfig'],
        "runactions"		=> ['isAvcdRunning', 'checkMemory', 
                                #['scanIngress', 15],
                                ['validateIngress', 2], 
                                'ingressContains',
                                ['validateEgress', 10], 
                                #['egressContainsPids', ((), 0, [800, 801,802], 200)], # set wanted pids dynamically
                                ['egressContains', ("AC-3", "AVC")],
                                ['validateMux', (10)],
                                #['checkMdiDf', (10)],
                                
                                ['validateEgress', 10, "234.1.1.82"], 
                                ['egressContainsPids', ([0,1000,2000,8191], 0, [], 0)],
                                #['egressContains', ("none", "AVC")],
                                ['validateMux', (10), "pip"],

                                ['pause',(5)] ],
		"postrunactions" 	=>  ['stopAvcd'],
	},

    310000 => {
        "id"               => "310000",
        "name"	           => "blank (set automatically)",
        "narrative"        => "manual test",
        "teststeps"        => [("",
                               )],
        "history"          => "added by kodell, March 13, 2013, for avcd-3.0.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],

        "postrunactions"   => [],
    },
    330000 => {
        "id"               => "330000",
        "name"	           => "blank (set automatically)",
        "narrative"        => "manual test",
        "teststeps"        => [("",
                               )],
        "history"          => "added by kodell, July 2, 2013, for avcd-3.1.0",
        "prerunactions"    => [],
        "startactions"	   => [],
        "runactions"       => ['manualTest'],

        "postrunactions"   => [],
    },

	# This is a batch test, in other words a test that runs other tests
	# ONLY the id, name, and narrative fields are required, all others are
	# pulled from the individual test cases.
	# The name field defines what tests to run: batch=id1,id2,id3
	1000000 => {
		"id"				=> "1000000",
		"name"				=> "Batch test: Generic nightly build.",
		"testList"			=>	[50000,50100,50200,60000,22222,33333,44444],
		"narrative"			=> "Running nightly build tests, validates todays build against starting/stoping avcd, ingress/egress......",
	},
    

	
);


# A hash of AVCD configuration presets.
#
# The anonymous array is configured as follows:
# 0 = A comma seperated list of AVCD versions that can use this preset
# 1 = A text description of the preset
# 2 = The actual AVCD presets that would be found in the conf file, as an anonymous array
#

our %avcdPresets = (
    200 => [    '3.0.0.39729', 
				'MPEG2HD720-MPEG4HD720', 
                "runtime/avcd-3/200", 
                "SET:COMM_CONF=1;debug=0;context=MPEG4HD720",
                "SET:ADD_NODE=reader;name=reader;SRCADDR;SRCPORT;reader-discontinuity-threshold-backward=0.25;reader-discontinuity-threshold-forward=0.50",
                "SET:ADD_NODE=avcd_decoder;name=video_decoder;debug=0;bp-threshold=200",
                "SET:ADD_NODE=muxer;name=muxer;mux-video-maxdelay=0.9;mux-vbv-maxrate=5500;mux-reorder-delay=1;mux-rap=1;no-extra-desc=1;bp-threshold=1000000",
                "SET:ADD_NODE=video_encoder;name=video_encoder;width=1280;height=720;dst-video-pid=481;dst-video-codec=avc;no-input-threshold=4;x264-bitrate=4300;x264-vbv-maxrate=4300;x264-vbv-bufsize=4300;x264-aud=1;x264-me=dia;x264-subme=2;x264-ref=3;x264-bframes=1;x264-b-adapt=1;x264-min-keyint=15;x264-rc-lookahead=30;x264-keyint=30;x264-trellis=0;x264-partitions=all;x264-8x8dct=1;x264-no-psnr=1;x264-no-ssim=1;x264-scenecut=40;x264-sar=1:1;x264-threads=8;x264-no-cabac=0;x264-speed=1.1;x264-speed-bufsize=90;x264-aq-strength=0.7",
                "SET:ADD_NODE=mcast_writer;name=writer;DSTADDR;DSTPORT;output-delay=8;mux-vbv-maxrate=6000",
                "SET:WIRE=reader,video_decoder-481,muxer-482",
                "SET:WIRE=video_decoder,video_encoder",
                "SET:WIRE=video_encoder,muxer",
                "SET:WIRE=muxer,writer",
                "START"
                ],
    201 => [    '3.0.0.39729', 
				'MPEG2HD720-MPEG4HD720', 
                "runtime/avcd-3/201", 
                "SET:COMM_CONF=1;debug=0;context=MPEG4HD720",
                "SET:ADD_NODE=reader;name=reader;SRCADDR;SRCPORT;reader-discontinuity-threshold-backward=0.25;reader-discontinuity-threshold-forward=0.50",
                "SET:ADD_NODE=avcd_decoder;name=video_decoder;debug=0;bp-threshold=200",
                "SET:ADD_NODE=muxer;name=muxer;mux-video-maxdelay=0.9;mux-vbv-maxrate=5500;mux-reorder-delay=1;mux-rap=1;no-extra-desc=1;bp-threshold=1000000",
                #"SET:ADD_NODE=video_encoder;name=video_encoder;width=1280;height=720;dst-video-pid=481;dst-video-codec=avc;no-input-threshold=4;x264-bitrate=4300;x264-vbv-maxrate=4300;x264-vbv-bufsize=4300;x264-aud=1;x264-me=dia;x264-subme=2;x264-ref=3;x264-bframes=1;x264-b-adapt=1;x264-min-keyint=15;x264-rc-lookahead=30;x264-keyint=30;x264-trellis=0;x264-partitions=all;x264-8x8dct=1;x264-no-psnr=1;x264-no-ssim=1;x264-scenecut=40;x264-sar=1:1;x264-threads=8;x264-no-cabac=0;x264-speed=1.1;x264-speed-bufsize=90;x264-aq-strength=0.7",
                "SET:ADD_NODE=mcast_writer;name=writer;DSTADDR;DSTPORT;output-delay=8;mux-vbv-maxrate=6000",
                "SET:WIRE=reader,video_decoder-481,muxer-482",
                "SET:WIRE=video_decoder,video_encoder",
                "SET:WIRE=video_encoder,muxer",
                "SET:WIRE=muxer,writer",
                "START"
                ],
    205 => [    '3.0.0.40206', 
		'MPEG2HD720-MPEG4SD480p', 
                "runtime/avcd-3/205", 
                "SET:COMM_CONF=1;debug=0;context=FOX Desportes SD",
                "SET:ADD_NODE=reader;name=reader;SRCADDR;SRCPORT;reader-discontinuity-threshold-backward=0.25;reader-discontinuity-threshold-forward=0.50",
                "SET:ADD_NODE=avcd_decoder;name=video_decoder;debug=0;bp-threshold=100000",
                "SET:ADD_NODE=muxer;psi-interval=0.450;name=muxer;mux-video-maxdelay=1.1;mux-vbv-maxrate=2500;mux-reorder-delay=1;mux-rap=1;no-extra-desc=1;bp-threshold=100000",
                "SET:ADD_NODE=video_encoder;name=video_encoder;height=480;width=640;dst-video-pid=481;dst-video-codec=avc;no-input-threshold=4;x264-aq-strength=0.7;x264-aud=1;x264-b-adapt=1;x264-bframes=1;x264-bitrate=1900;x264-keyint=30;x264-me=dia;x264-min-keyint=15;x264-no-psnr=1;x264-no-ssim=1;x264-partitions=all;x264-rc-lookahead=15;x264-ref=3;x264-scenecut=40;x264-speed-bufsize=300;x264-speed=1.1;x264-subme=2;x264-threads=6;x264-trellis=0;x264-vbv-bufsize=2000;x264-vbv-maxrate=2000;bp-threshold=100000",
                "SET:ADD_NODE=autoscale_filter;name=autoscale;autoscale=640|480|4|3|scale;bp-threshold=100000",
                "SET:ADD_NODE=interlace_filter;name=interlace;interlaced=1;bp-threshold=100000",
                "SET:ADD_NODE=mcast_writer;name=writer;DSTADDR;DSTPORT;output-delay=8;mux-vbv-maxrate=2500;bp-threshold=100000",
                "SET:WIRE=reader,video_decoder-481,muxer-482",
                "SET:WIRE=video_decoder,autoscale",
                "SET:WIRE=autoscale,interlace",
                "SET:WIRE=interlace,video_encoder",
                "SET:WIRE=video_encoder,muxer",
                "SET:WIRE=muxer,writer",
                "START"
    ],
    210 => [    '3.0.0.39729', 
				'MPEG2HD720-MPEG4HD720', 
                "runtime/avcd-3/210", 
                "SET:COMM_CONF=1;debug=0;context=MPEG4HD720p",
                "SET:ADD_NODE=reader;name=reader;SRCADDR;SRCPORT;reader-discontinuity-threshold-backward=0.25;reader-discontinuity-threshold-forward=0.50",
                "SET:ADD_NODE=avcd_decoder;name=video_decoder;debug=0;bp-threshold=200",
                "SET:ADD_NODE=muxer;name=muxer;mux-video-maxdelay=0.9;mux-vbv-maxrate=5400;mux-reorder-delay=1;mux-rap=1;no-extra-desc=1;bp-threshold=1000000;mux-audio-bitrate=448;mux-audio-maxdelay=0.7;dst-pmt-pid=1000;scte35-pid=600;dst-video-pid=2000;dst-audio1-pid=3000;dst-audio2-pid=3001;psi-interval=0.450",

                "SET:ADD_NODE=autoscale_filter;NAME=pip_filter;debug=0;autoscale=192|192|1|1|expand;exit-on-completion=0;context=Gen purpose AVCD reuse;x264-sar=192/192",
                "SET:ADD_NODE=video_encoder;NAME=pip_encoder;x264-trellis=0;x264-sar=1|1;x264-threads=8;x264-ref=0;width=192;x264-min-keyint=15;x264-me=dia;x264-partitions=all;x264-speed-bufsize=90;x264-bitrate=220;no-input-threshold=4;x264-8x8dct=0;dst-video-codec=avc;x264-vbv-maxrate=220;x264-b-adapt=0;exit-on-completion=0;x264-subme=1;context=Gen purpose AVCD reuse;x264-bframes=0;closed-caption-opt=None;x264-speed=1.1;x264-scenecut=40;x264-aq-strength=0.7;x264-keyint=30;x264-aud=1;x264-vbv-bufsize=220;debug=0;x264-rc-lookahead=5;height=192",
                "SET:ADD_NODE=muxer;NAME=pip_muxer;mux-video-maxdelay=0.9;af-max-time=0.030;psi-interval=0.450;mux-vbv-maxrate=300;context=Gen purpose AVCD reuse;debug=0;no-extra-desc=1;exit-on-completion=0;mux-reorder-delay=1;dst-pmt-pid=1000;dst-video-pid=2000;psi-interval=0.450;scte35-pid=600;",

                "SET:ADD_NODE=video_encoder;name=video_encoder;width=1280;height=720;dst-video-codec=avc;no-input-threshold=4;x264-bitrate=4536;x264-vbv-maxrate=4600;x264-vbv-bufsize=4600;x264-aud=1;x264-me=dia;x264-subme=2;x264-ref=3;x264-bframes=1;x264-b-adapt=1;x264-min-keyint=15;x264-rc-lookahead=30;x264-keyint=30;x264-trellis=0;x264-partitions=all;x264-8x8dct=1;x264-no-psnr=1;x264-no-ssim=1;x264-scenecut=40;x264-sar=1:1;x264-threads=8;x264-no-cabac=0;x264-speed=1.1;x264-speed-bufsize=90;x264-aq-strength=0.7",
                "SET:ADD_NODE=mcast_writer;name=writer;DSTADDR;DSTPORT;output-delay=8;mux-vbv-maxrate=5400",
                "SET:ADD_NODE=mcast_writer;name=pip_writer;dst-addr=234.1.1.12;dst-port=5500;output-delay=8;mux-vbv-maxrate=300",
                "SET:WIRE=reader,video_decoder-481,muxer-482",
                "SET:WIRE=video_decoder,pip_filter,video_encoder",
                "SET:WIRE=video_encoder,muxer",
                "SET:WIRE=muxer,writer",
                "SET:WIRE=pip_filter,pip_encoder",
                "SET:WIRE=pip_encoder,pip_muxer",
                "SET:WIRE=pip_muxer,pip_writer",
                "START"
    ],


    300 => [    '3.0.0.39729', 
				'MPEG2HD1080i-MPEG4HD1080i', 
                "runtime/avcd-3/300", 
                "SET:COMM_CONF=1;debug=0;context=MPEG4HD1080i",
                "SET:ADD_NODE=reader;name=reader;SRCADDR;SRCPORT;reader-discontinuity-threshold-backward=0.25;reader-discontinuity-threshold-forward=0.50;scte35-pid=600",
                "SET:ADD_NODE=avcd_decoder;name=video_decoder;debug=0;bp-threshold=200",
                "SET:ADD_NODE=muxer;name=muxer;mux-video-maxdelay=0.9;mux-vbv-maxrate=5500;mux-reorder-delay=1;mux-rap=1;no-extra-desc=1;bp-threshold=1000000;dst-pmt-pid=1000;dst-video-pid=2000;dst-audio1-pid=3000;dst-audio2-pid=3001;psi-interval=0.450;",
                "SET:ADD_NODE=video_encoder;name=video_encoder;width=1920;height=1080;dst-video-codec=avc;no-input-threshold=4;x264-bitrate=4300;x264-vbv-maxrate=4300;x264-vbv-bufsize=4300;x264-aud=1;x264-me=dia;x264-subme=2;x264-ref=3;x264-bframes=1;x264-b-adapt=1;x264-min-keyint=15;x264-rc-lookahead=30;x264-keyint=30;x264-trellis=0;x264-partitions=all;x264-8x8dct=1;x264-no-psnr=1;x264-no-ssim=1;x264-scenecut=40;x264-sar=1:1;x264-threads=8;x264-no-cabac=0;x264-speed=1.1;x264-speed-bufsize=90;x264-aq-strength=0.7",
                "SET:ADD_NODE=mcast_writer;name=writer;DSTADDR;DSTPORT;output-delay=8;mux-vbv-maxrate=6000",
                "SET:WIRE=reader,video_decoder-481,muxer-482",
                "SET:WIRE=video_decoder,video_encoder",
                "SET:WIRE=video_encoder,muxer",
                "SET:WIRE=muxer,writer",
                "START"
                ],


    301 => [    '3.0.0.39729', 
				'MPEG2HD1080i-MPEG4HD1080i', 
                "runtime/avcd-3/301", 
                "SET:COMM_CONF=1;debug=0;context=MPEG4HD1080i",
                "SET:ADD_NODE=reader;name=reader;SRCADDR;SRCPORT;reader-discontinuity-threshold-backward=0.25;reader-discontinuity-threshold-forward=0.50;scte35-pid=600",
                "SET:ADD_NODE=avcd_decoder;name=video_decoder;debug=0;bp-threshold=200",
                "SET:ADD_NODE=muxer;name=muxer;mux-video-maxdelay=0.9;mux-vbv-maxrate=5500;mux-reorder-delay=1;mux-rap=1;no-extra-desc=1;bp-threshold=1000000;dst-pmt-pid=1000;dst-video-pid=2000;dst-audio1-pid=3000;dst-audio2-pid=3001;psi-interval=0.450",
                
                "SET:ADD_NODE=video_encoder;name=video_encoder;width=1920;height=1080;dst-video-codec=avc;no-input-threshold=4;x264-bitrate=4300;x264-vbv-maxrate=4300;x264-vbv-bufsize=4300;x264-aud=1;x264-me=dia;x264-subme=2;x264-ref=3;x264-bframes=1;x264-b-adapt=1;x264-min-keyint=15;x264-rc-lookahead=30;x264-keyint=30;x264-trellis=0;x264-partitions=all;x264-8x8dct=1;x264-no-psnr=1;x264-no-ssim=1;x264-scenecut=40;x264-sar=1:1;x264-threads=8;x264-no-cabac=0;x264-speed=1.1;x264-speed-bufsize=90;x264-aq-strength=0.7",
                "SET:ADD_NODE=mcast_writer;name=writer;DSTADDR;DSTPORT;output-delay=8;mux-vbv-maxrate=6000",
                #"SET:WIRE=reader,video_decoder,muxer",
                "SET:WIRE=reader,video_decoder-481,muxer-482",
                "SET:WIRE=video_decoder,video_encoder",
                "SET:WIRE=video_encoder,muxer",
                "SET:WIRE=muxer,writer",
                "START"
                ],
    310 => [    '3.0.0.39729', 
				'MPEG2HD1080i-MPEG4HD1080i', 
                "runtime/avcd-3/310", 
                "SET:COMM_CONF=1;debug=0;context=MPEG4HD1080i",
                "SET:ADD_NODE=reader;name=reader;SRCADDR;SRCPORT;reader-discontinuity-threshold-backward=0.25;reader-discontinuity-threshold-forward=0.50",
                "SET:ADD_NODE=avcd_decoder;name=video_decoder;debug=0;nice-setting=-19;bp-threshold=100000",
                "SET:ADD_NODE=muxer;name=muxer;mux-video-maxdelay=0.9;mux-vbv-maxrate=5400;mux-reorder-delay=1;mux-rap=1;no-extra-desc=1;bp-threshold=1000000;mux-audio-bitrate=384;mux-audio-maxdelay=0.7;dst-pmt-pid=1000;scte35-pid=600;dst-video-pid=2000;dst-audio1-pid=3000;dst-audio2-pid=3001;psi-interval=0.450",

                "SET:ADD_NODE=autoscale_filter;NAME=pip_filter;debug=0;autoscale=192|192|1|1|expand;exit-on-completion=0;context=Gen purpose AVCD reuse;x264-sar=192/192",
                "SET:ADD_NODE=video_encoder;NAME=pip_encoder;x264-trellis=0;x264-sar=1|1;x264-threads=8;x264-ref=0;width=192;x264-min-keyint=15;x264-me=dia;x264-partitions=all;x264-speed-bufsize=90;x264-bitrate=220;no-input-threshold=4;x264-8x8dct=0;dst-video-codec=avc;x264-vbv-maxrate=220;x264-b-adapt=0;exit-on-completion=0;x264-subme=1;context=Gen purpose AVCD reuse;x264-bframes=0;closed-caption-opt=None;x264-speed=1.1;x264-scenecut=40;x264-aq-strength=0.7;x264-keyint=30;x264-aud=1;x264-vbv-bufsize=220;debug=0;x264-rc-lookahead=5;height=192",
                "SET:ADD_NODE=muxer;NAME=pip_muxer;mux-video-maxdelay=0.9;af-max-time=0.030;psi-interval=0.450;mux-vbv-maxrate=300;context=Gen purpose AVCD reuse;debug=0;no-extra-desc=1;exit-on-completion=0;mux-reorder-delay=1;dst-pmt-pid=1000;dst-video-pid=2000;psi-interval=0.450;scte35-pid=600;",

                "SET:ADD_NODE=video_encoder;name=video_encoder;width=1920;height=1080;dst-video-codec=avc;no-input-threshold=4;x264-bitrate=4200;x264-vbv-maxrate=4200;x264-vbv-bufsize=4200;x264-aud=1;x264-me=dia;x264-subme=2;x264-ref=3;x264-bframes=1;x264-b-adapt=1;x264-min-keyint=15;x264-rc-lookahead=30;x264-keyint=30;x264-trellis=0;x264-partitions=all;x264-8x8dct=1;x264-no-psnr=1;x264-no-ssim=1;x264-scenecut=40;x264-sar=1:1;x264-threads=8;x264-no-cabac=0;x264-speed=1.1;x264-speed-bufsize=300;x264-aq-strength=0.7;x264-interlaced=1",
                "SET:ADD_NODE=mcast_writer;name=writer;DSTADDR;DSTPORT;output-delay=16;mux-vbv-maxrate=5400",
                "SET:ADD_NODE=mcast_writer;name=pip_writer;dst-addr=234.1.1.12;dst-port=5500;output-delay=8;mux-vbv-maxrate=300",
                "SET:WIRE=reader,video_decoder-481,muxer-482",
                "SET:WIRE=video_decoder,pip_filter,video_encoder",
                "SET:WIRE=video_encoder,muxer",
                "SET:WIRE=muxer,writer",
                "SET:WIRE=pip_filter,pip_encoder",
                "SET:WIRE=pip_encoder,pip_muxer",
                "SET:WIRE=pip_muxer,pip_writer",
                "START"
                ],
    #"SET:ADD_NODE=muxer;NAME=muxer;mux-reorder-delay=1;no-extra-desc=1;bp-threshold=100000;context=HGTV_E_HD;mux-vbv-maxrate=5400;mux-audio-maxdelay=0.7;exit-on-completion=0;mux-audio-bitrate=404;psi-interval=0.450;mux-rap=1;mux-video-maxdelay=0.9",
    320 => [    '3.0.0.39729', 
				'MPEG2HD1080i-MPEG4HD1080i', 
                "runtime/avcd-3/320", 
                "SET:COMM_CONF=1;debug=0;context=MPEG4HD1080i",
                "SET:ADD_NODE=reader;NAME=reader;reader-discontinuity-threshold-backward=0.65;SRCADDR;SRCPORT;reader-discontinuity-threshold-forward=0.65",
                "SET:ADD_NODE=avcd_decoder;NAME=decoder;nice-setting=-19;exit-on-completion=0;context=HGTV_E_HD;bp-threshold=100000",
                "SET:ADD_NODE=muxer;NAME=muxer;mux-reorder-delay=1;no-extra-desc=1;bp-threshold=100000;context=HGTV_E_HD;mux-vbv-maxrate=5400;mux-audio-maxdelay=0.035;exit-on-completion=0;mux-audio-bitrate=400;psi-interval=0.450;mux-rap=1;mux-video-maxdelay=0.9;dst-pmt-pid=1000;scte35-pid=600;dst-video-pid=2000;dst-audio1-pid=3000;dst-audio2-pid=3001",

                "SET:ADD_NODE=autoscale_filter;NAME=pip_filter;autoscale=192|192|1|1|expand;exit-on-completion=0;context=HGTV_E_HD;bp-threshold=100000;x264-sar=192/192",
                "SET:ADD_NODE=video_encoder;NAME=encoder;x264-trellis=0;x264-sar=1|1;x264-threads=6;x264-ref=3;width=1920;x264-min-keyint=15;x264-me=dia;x264-no-psnr=1;x264-partitions=all;x264-speed-bufsize=90;x264-bitrate=4600;no-input-threshold=4;x264-8x8dct=1;dst-video-codec=avc;x264-vbv-maxrate=4600;x264-b-adapt=1;exit-on-completion=0;x264-subme=2;x264-interlaced=1;context=HGTV_E_HD;x264-bframes=1;x264-no-cabac=0;x264-speed=1.1;x264-scenecut=40;x264-no-ssim=1;x264-aq-strength=0.7;x264-keyint=30;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=4600;x264-rc-lookahead=30;height=1080",
                "SET:ADD_NODE=mcast_writer;NAME=writer;mux-vbv-maxrate=5400;context=HGTV_E_HD;output-delay=8;DSTADDR;DSTPORT;exit-on-completion=0;bp-threshold=100000",
                "SET:ADD_NODE=video_encoder;NAME=pip_encoder;x264-trellis=0;x264-sar=1|1;x264-threads=8;x264-ref=0;width=192;x264-min-keyint=15;x264-me=dia;x264-partitions=all;x264-speed-bufsize=90;x264-bitrate=220;no-input-threshold=4;x264-8x8dct=0;dst-video-codec=avc;x264-vbv-maxrate=220;x264-b-adapt=0;exit-on-completion=0;x264-subme=1;context=HGTV_E_HD;x264-bframes=0;closed-caption-opt=None;x264-speed=1.1;x264-scenecut=40;x264-aq-strength=0.7;x264-keyint=30;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=220;x264-rc-lookahead=5;height=192",
                "SET:ADD_NODE=muxer;NAME=pip_muxer;mux-video-maxdelay=0.9;af-max-time=0.030;psi-interval=0.450;mux-vbv-maxrate=300;context=HGTV_E_HD;no-extra-desc=1;exit-on-completion=0;bp-threshold=100000;mux-reorder-delay=1",
                "SET:ADD_NODE=mcast_writer;NAME=pip_writer;dst-port=5500;dst-addr=234.1.1.12;exit-on-completion=0;context=HGTV_E_HD;mux-vbv-maxrate=300",
                "SET:WIRE=reader,decoder-481,muxer-482",
                "SET:WIRE=decoder,pip_filter,encoder",
                "SET:WIRE=muxer,writer",
                "SET:WIRE=pip_filter,pip_encoder",
                "SET:WIRE=encoder,muxer",
                "SET:WIRE=pip_encoder,pip_muxer",
                "SET:WIRE=pip_muxer,pip_writer",
                "START"
    ],
    400 => [    '3.0.0.39729', 
				'MPEG4SD480p-MPEG2SD480p', 
                "runtime/avcd-3/400", 
                "SET:COMM_CONF=1;debug=0;context=MPEG4SD480p-MPEG2SD480p",
                "SET:ADD_NODE=reader;name=reader;SRCADDR;SRCPORT",
                "SET:ADD_NODE=avcd_decoder;name=video_decoder;debug=0;bp-threshold=64;src-video-codec=avc",
#                "SET:ADD_NODE=muxer;name=muxer;mux-video-maxdelay=0.9;mux-vbv-maxrate=5500;mux-reorder-delay=1;mux-rap=1;no-extra-desc=1;bp-threshold=1000000",
                "SET:ADD_NODE=muxer;name=muxer;mux-video-maxdelay=0.4;mux-vbv-maxrate=4521;dst-program-id=514;mux-reorder-delay=1;mux-rap=1;no-extra-desc=1",
                "SET:ADD_NODE=video_encoder;name=video_encoder;width=528;height=480;dst-video-codec=mpeg2;x264-bitrate=3900;x264-vbv-maxrate=3900;x264-vbv-bufsize=1835;dst-video-pid=481;x264-aud=1;x264-me=hex;x264-subme=8;x264-ref=1;x264-bframes=2;x264-b-adapt=2;x264-min-keyint=15;x264-rc-lookahead=40;x264-keyint=30;x264-trellis=0;x264-partitions=none;x264-8x8dct=0;x264-scenecut=15;x264-sar=4:3;x264-threads=4;x264-aq-strength=1.1;no-input-threshold=4;x264-interlaced=1",
                "SET:ADD_NODE=mcast_writer;name=writer;DSTADDR;DSTPORT;output-delay=8;mux-vbv-maxrate=6000",
                "SET:WIRE=reader,video_decoder-481,muxer-482",
                "SET:WIRE=video_decoder,video_encoder",
                "SET:WIRE=video_encoder,muxer",
                "SET:WIRE=muxer,writer",
                "START"
                ],
    410 => [    '3.0.0.39729', 
				'MPEG4SD480p-MPEG2SD480p', 
                "runtime/avcd-3/410", 
                "SET:COMM_CONF=1;debug=0;context=MPEG4SD480p-MPEG2SD480p",

                "SET:ADD_NODE=reader;NAME=reader;reader-discontinuity-threshold-backward=0.65;SRCADDR;SRCPORT;reader-discontinuity-threshold-forward=0.65",
                "SET:ADD_NODE=avcd_decoder;NAME=decoder;nice-setting=-19;bp-threshold=100000",
                "SET:ADD_NODE=muxer;NAME=muxer;dst-video-pid=481;dst-pmt-pid=480;mux-reorder-delay=1;no-extra-desc=1;dst-audio1-pid=482;bp-threshold=100000;mux-vbv-maxrate=4400;mux-audio-maxdelay=0.02;mux-audio-bitrate=160;psi-interval=0.450;mux-rap=1;mux-video-maxdelay=1.04",
                "SET:ADD_NODE=autoscale_filter;NAME=autoscale;autoscale=528|480|4|3|expand;bp-threshold=100000;x264-sar=1920/1584",
                "SET:ADD_NODE=video_encoder;NAME=encoder;x264-trellis=0;x264-sar=4|3;x264-threads=4;x264-ref=3;width=528;x264-min-keyint=15;x264-me=dia;x264-no-psnr=1;x264-partitions=all;x264-bitrate=3878;no-input-threshold=4;x264-8x8dct=1;dst-video-codec=mpeg2;x264-vbv-maxrate=3878;x264-b-adapt=1;x264-subme=2;x264-interlaced=1;x264-bframes=1;x264-no-cabac=0;x264-scenecut=40;x264-no-ssim=1;x264-aq-strength=0.7;x264-keyint=30;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=3878;x264-rc-lookahead=30;height=480",
                "SET:ADD_NODE=mcast_writer;nice-setting=-15;NAME=writer;output-delay=8;DSTADDR;DSTPORT;mux-vbv-maxrate=4400;bp-threshold=100000;",
                "SET:WIRE=reader,decoder-481,muxer-482",
                "SET:WIRE=decoder,autoscale",
                "SET:WIRE=muxer,writer",
                "SET:WIRE=autoscale,encoder",
                "SET:WIRE=encoder,muxer",

                # auto settings that dont work
                #"SET:ADD_NODE=reader;NAME=reader;reader-discontinuity-threshold-backward=0.65;SRCADDR;SRCPORT;reader-discontinuity-threshold-forward=0.65",
                ##SET:ADD_NODE=avcd_decoder;NAME=decoder;nice-setting=-19;bp-threshold=100000",
                #"SET:ADD_NODE=muxer;NAME=muxer;dst-video-pid=481;dst-pmt-pid=480;mux-reorder-delay=1;no-extra-desc=1;dst-audio1-pid=482;bp-threshold=100000;mux-vbv-maxrate=4400;mux-audio-maxdelay=0.02;mux-audio-bitrate=160;psi-interval=0.450;mux-rap=1;mux-video-maxdelay=1.04",
                #"SET:ADD_NODE=autoscale_filter;NAME=autoscale;autoscale=528|480|4|3|expand;bp-threshold=100000;x264-sar=1920/1584",
                #"SET:ADD_NODE=video_encoder;NAME=encoder;x264-trellis=0;x264-sar=4|3;x264-threads=6;x264-ref=3;width=528;x264-min-keyint=15;x264-me=dia;x264-no-psnr=1;x264-partitions=all;x264-bitrate=3878;no-input-threshold=4;x264-8x8dct=1;dst-video-codec=mpeg2;x264-vbv-maxrate=3878;x264-b-adapt=1;x264-subme=2;x264-interlaced=1;x264-bframes=1;x264-no-cabac=0;x264-scenecut=40;x264-no-ssim=1;x264-aq-strength=0.7;x264-keyint=30;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=3878;x264-rc-lookahead=30;height=480",
                #"SET:ADD_NODE=mcast_writer;NAME=writer;output-delay=8;DSTADDR;DSTPORT;mux-vbv-maxrate=4400;bp-threshold=10000;",
                #"SET:WIRE=reader,decoder-481,muxer-482",
                #"SET:WIRE=decoder,autoscale",
                #"SET:WIRE=muxer,writer",
                #"SET:WIRE=autoscale,encoder",
                #"SET:WIRE=encoder,muxer",
                "START"
    ],



    500 => [    '3.0.0.39729', 
				'MPEG2SD480p-MPEG4SD480p', 
                "runtime/avcd-3/500", 
                "SET:COMM_CONF=1;debug=0;context=MPEG2SD480p-MPEG4SD480p",
                "SET:ADD_NODE=reader;NAME=reader;reader-discontinuity-threshold-backward=0.50;SRCADDR;SRCPORT;reader-discontinuity-threshold-forward=0.50",
                "SET:ADD_NODE=avcd_decoder;NAME=mpeg2_decoder;nice-setting=-19;bp-threshold=100000",
                "SET:ADD_NODE=muxer;psi-interval=0.450;NAME=muxer_1600Kbps;mux-reorder-delay=1;mux-video-maxdelay=0.9;no-extra-desc=1;mux-rap=1;mux-vbv-maxrate=1600;bp-threshold=100000;mux-audio-bitrate=192;mux-audio-maxdelay=0.7;dst-pmt-pid=1000;scte35-pid=600;dst-video-pid=2000;dst-audio1-pid=3000;dst-audio2-pid=3001",
                "SET:ADD_NODE=video_encoder;NAME=h264_528_480_1258i;x264-trellis=0;x264-sar=40|33;x264-threads=6;x264-ref=3;width=528;x264-min-keyint=15;x264-me=dia;x264-partitions=all;x264-speed-bufsize=300;x264-bitrate=1258;x264-8x8dct=0;no-input-threshold=4;dst-video-codec=avc;x264-vbv-maxrate=1258;x264-b-adapt=1;x264-subme=2;x264-interlaced=1;x264-bframes=1;x264-speed=1.1;x264-scenecut=40;x264-keyint=30;x264-aud=1;x264-vbv-bufsize=944;x264-rc-lookahead=30;height=480",
                "SET:ADD_NODE=mcast_writer;NAME=mcast_1600kbits_43;DSTPORT;DSTADDR;output-delay=8;mux-vbv-maxrate=1600;bp-threshold=100000",
                "SET:WIRE=reader,mpeg2_decoder-481,muxer_1600Kbps-482",
                "SET:WIRE=mpeg2_decoder,h264_528_480_1258i",
                "SET:WIRE=h264_528_480_1258i,muxer_1600Kbps",
                "SET:WIRE=muxer_1600Kbps,mcast_1600kbits_43",
                "START"
                ],
    510 => [    '3.0.0.39729', 
				'MPEG2SD480p-MPEG4SD480p', 
                "runtime/avcd-3/510", 
                "SET:COMM_CONF=1;debug=0;context=MPEG2SD480p-MPEG4SD480p",
                "SET:ADD_NODE=reader;NAME=reader;reader-discontinuity-threshold-backward=0.50;SRCADDR;SRCPORT;reader-discontinuity-threshold-forward=0.50",
                "SET:ADD_NODE=avcd_decoder;NAME=mpeg2_decoder;nice-setting=-19;bp-threshold=100000",
                "SET:ADD_NODE=muxer;psi-interval=0.450;NAME=muxer_1600Kbps;mux-reorder-delay=1;mux-video-maxdelay=0.9;no-extra-desc=1;mux-rap=1;mux-vbv-maxrate=1600;bp-threshold=100000;mux-audio-bitrate=384;mux-audio-maxdelay=0.7;dst-pmt-pid=1000;scte35-pid=600;dst-video-pid=2000;dst-audio1-pid=3000;dst-audio2-pid=3001",
                "SET:ADD_NODE=video_encoder;NAME=h264_528_480_1258i;x264-trellis=0;x264-sar=40|33;x264-threads=6;x264-ref=3;width=528;x264-min-keyint=15;x264-me=dia;x264-partitions=all;x264-speed-bufsize=300;x264-bitrate=958;x264-8x8dct=0;no-input-threshold=4;dst-video-codec=avc;x264-vbv-maxrate=958;x264-b-adapt=1;x264-subme=2;x264-interlaced=1;x264-bframes=1;x264-speed=1.1;x264-scenecut=40;x264-keyint=30;x264-aud=1;x264-vbv-bufsize=958;x264-rc-lookahead=30;height=480",
                "SET:ADD_NODE=mcast_writer;NAME=mcast_1600kbits_43;DSTPORT;DSTADDR;output-delay=8;mux-vbv-maxrate=1600;bp-threshold=100000",
                "SET:WIRE=reader,mpeg2_decoder-481,muxer_1600Kbps-482",
                "SET:WIRE=mpeg2_decoder,h264_528_480_1258i",
                "SET:WIRE=h264_528_480_1258i,muxer_1600Kbps",
                "SET:WIRE=muxer_1600Kbps,mcast_1600kbits_43",
                "START"
    ],

    520 => [    '3.0.0.41963', 
				'MPEG2HD720p-MPEG4SD480p', 
                "runtime/avcd-3/520", 
                "SET:COMM_CONF=1;",
                "SET:ADD_NODE=reader;NAME=reader;src-audio1-codecs=AC3;reader-discontinuity-threshold-backward=0.65;SRCPORT;SRCADDR;reader-discontinuity-threshold-forward=0.65",
                "SET:ADD_NODE=avcd_decoder;NAME=decoder;nice-setting=-19;bp-threshold=100000",
                "SET:ADD_NODE=muxer;NAME=muxer;dst-video-pid=2000;dst-pmt-pid=1000;mux-reorder-delay=1;no-extra-desc=1;dst-audio1-pid=3000;bp-threshold=100000;mux-vbv-maxrate=1600;mux-audio-maxdelay=0.065;mux-audio-bitrate=403;psi-interval=0.450;mux-rap=1;mux-video-maxdelay=0.001",
                #"SET:ADD_NODE=muxer;NAME=muxer;dst-video-pid=2000;dst-pmt-pid=1000;mux-reorder-delay=1;no-extra-desc=1;dst-audio1-pid=3000;bp-threshold=100000;mux-vbv-maxrate=1600;mux-audio-maxdelay=0.065;mux-audio-bitrate=403;psi-interval=0.450;mux-rap=1;mux-video-maxdelay=0.900",
                "SET:ADD_NODE=autoscale_filter;NAME=pip_autoscale;autoscale=192|192|4|3|expand;bp-threshold=100000",
                "SET:ADD_NODE=autoscale_filter;NAME=autoscale;autoscale=528|480|4|3|expand;bp-threshold=100000",
                "SET:ADD_NODE=interlace_filter;NAME=interlace;interlaced=1;bp-threshold=100000",
    # tweaked            "SET:ADD_NODE=video_encoder;NAME=encoder;x264-trellis=0;x264-sar=40|33;x264-threads=4;x264-ref=3;width=528;x264-min-keyint=15;x264-me=dia;x264-no-psnr=1;x264-partitions=all;x264-speed-bufsize=90;x264-bitrate=883;x264-8x8dct=0;no-input-threshold=4;dst-video-codec=avc;x264-b-adapt=1;x264-subme=2;x264-interlaced=1;x264-bframes=2;closed-caption-opt=SCTE20Convert;x264-no-cabac=0;x264-speed=1.1;x264-scenecut=40;x264-no-ssim=1;x264-aq-strength=0.7;x264-keyint=30;bp-threshold=100000;x264-aud=1;x264-rc-lookahead=30;height=480;x264-vbv-bufsize=2400;x264-vbv-maxrate=883",

                "SET:ADD_NODE=video_encoder;NAME=encoder;x264-trellis=0;x264-sar=40|33;x264-threads=4;x264-ref=3;width=528;x264-min-keyint=15;x264-me=dia;x264-no-psnr=1;x264-partitions=all;x264-speed-bufsize=90;x264-bitrate=883;x264-8x8dct=0;no-input-threshold=4;dst-video-codec=avc;x264-vbv-maxrate=883;x264-b-adapt=1;x264-subme=2;x264-interlaced=1;x264-bframes=2;closed-caption-opt=SCTE20Convert;x264-no-cabac=0;x264-speed=1.1;x264-scenecut=40;x264-no-ssim=1;x264-aq-strength=0.7;x264-keyint=30;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=883;x264-rc-lookahead=30;height=480",
                # ORIG "SET:ADD_NODE=video_encoder;NAME=encoder;x264-trellis=0;x264-sar=40|33;x264-threads=4;x264-ref=3;width=528;x264-min-keyint=15;x264-me=dia;x264-no-psnr=1;x264-partitions=all;x264-speed-bufsize=90;x264-bitrate=883;x264-8x8dct=0;no-input-threshold=4;dst-video-codec=avc;x264-vbv-maxrate=883;x264-b-adapt=1;x264-subme=2;x264-interlaced=1;x264-bframes=2;closed-caption-opt=SCTE20Convert;x264-no-cabac=0;x264-speed=1.1;x264-scenecut=40;x264-no-ssim=1;x264-aq-strength=0.7;x264-keyint=30;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=883;x264-rc-lookahead=30;height=480",
                "SET:ADD_NODE=mcast_writer;NAME=writer;DSTPORT;nice-setting=-15;output-delay=8;DSTADDR;mux-vbv-maxrate=1600;bp-threshold=100000",
                "SET:ADD_NODE=framedrop_filter;NAME=pip_framedrop;fps=30000/1001;bp-threshold=100000;framedrop=1",
                "SET:ADD_NODE=video_encoder;NAME=pip_encoder;x264-trellis=1;x264-sar=4|3;x264-threads=3;x264-ref=2;width=192;x264-min-keyint=15;x264-me=hex;x264-partitions=all;x264-bitrate=220;x264-8x8dct=0;no-input-threshold=4;x264-vbv-maxrate=220;x264-b-adapt=1;x264-subme=5;x264-bframes=16;closed-caption-opt=None;x264-scenecut=5;x264-keyint=30;x264-aq-strength=1.0;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=220;x264-rc-lookahead=15;height=192",
                "SET:ADD_NODE=muxer;NAME=pip_muxer;mux-video-maxdelay=0.9;scte35-strip=1;af-max-time=0.030;psi-interval=0.450;dst-video-pid=2000;mux-vbv-maxrate=300;dst-pmt-pid=1000;no-extra-desc=1;bp-threshold=100000;mux-reorder-delay=1",
                "SET:ADD_NODE=mcast_writer;NAME=pip_writer;dst-port=5500;dst-addr=127.1.1.11;mux-vbv-maxrate=300",
                "SET:WIRE=reader,decoder-481,muxer-482",
                "SET:WIRE=decoder,pip_autoscale,autoscale",
                "SET:WIRE=muxer,writer",
                "SET:WIRE=pip_autoscale,pip_framedrop",
                "SET:WIRE=autoscale,interlace",
                "SET:WIRE=interlace,encoder",
                "SET:WIRE=encoder,muxer",
                "SET:WIRE=pip_framedrop,pip_encoder",
                "SET:WIRE=pip_encoder,pip_muxer",
                "SET:WIRE=pip_muxer,pip_writer",
                "START"
    ],

    580 => [    '3.0.0.41963', 
				'MPEG2SD480p-MPEG4SD480p', 
                "runtime/avcd-3/580", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;PIPS=234.1.1.12:5500;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;PROG_NUM=515",
#                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;PIPS=234.1.1.12:5500;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
                #"SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS=127.1.1.11:5500;PIPS_PMT_PID=1000;PIPS_PID=2000",
                "START"
    ],
    582 => [    '3.0.0.41963', 
				'MPEG2SD480p-MPEG4SD480p', 
                "runtime/avcd-3/582", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;PIPS=234.1.1.12:5500;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_PID=18;AUD2_SRC_PID=17;PROG_NUM=515",
#                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;PIPS=234.1.1.12:5500;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
                #"SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS=127.1.1.11:5500;PIPS_PMT_PID=1000;PIPS_PID=2000",
                "START"
    ],
    585 => [    '3.0.0.41963', 
				'MPEG2HD720p-MPEG4SD480p', 
                "runtime/avcd-3/580", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=2.5;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000",
                "START"
    ],
    590 => [    '3.0.0.41963', 
				'MPEG2HD1080i-MPEG4HD1080i',
                "runtime/avcd-3/590", 
                "SET:COMM_CONF=1;",
                #"SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000",
                #"SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;PIPS=234.1.1.12:5500;PIPS_PMT_PID=1000;PIPS_PID=2000",
                "SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PIPS=234.1.1.12:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
                #"SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PIPS=234.1.1.12:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
#                "SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PIPS=127.1.1.11:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
                "START"
    ],
    591 => [    '3.0.0.41963', 
				'MPEG2HD1080i-MPEG4HD1080i', 
                "runtime/avcd-3/591", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PIPS=127.1.1.11:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
                "START"
    ],
    595 => [    '3.0.0.41963', 
				'MPEG2SD480p-MPEG4SD480p', 
                "runtime/avcd-3/595", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PIPS=127.1.1.11:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000",
                "START"
    ],

    597 => [    '3.0.0.41963', 
				'MPEG2SD480p-MPEG4SD480p', 
                "runtime/avcd-3/597", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PIPS=127.1.1.1:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;PID=17;AUD2_SRC_PID=18",
                "START"
    ],
    598 => [    '3.0.0.41963', 
				'MPEG2SD480p-MPEG4SD480p', 
                "runtime/avcd-3/598", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PIPS=127.1.1.1:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
                #"SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PIPS=127.1.1.1:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD2_SRC_CODEC=ac3",
                "START"
    ],
    600 => [    '3.0.0.41963', 
                'MPEG2HD720p-MPEG4HD720p', 
                "runtime/avcd-3/600", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_720p;SOURCE;DEST;BITRATE=5.4;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;PIPS_PMT_PID=1000",
                #"SET:EGRESS=MP4_720p;SOURCE;DEST;BITRATE=5.4;PIPS=127.1.1.11:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000",
                "START"
    ],
    603 => [    '3.0.0.41963', 
                'MPEG2HD720p-MPEG4SD480p', 
                "runtime/avcd-3/603", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PIPS=127.1.1.11:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000",
                "START"
    ],


    605 => [    '3.0.0.41963', 
				'MPEG2HD1080i-MPEG4SD480p', 
                "runtime/avcd-3/605", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PIPS=127.1.1.11:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000",
                "START"
    ],
    700 => [    '3.0.0.41963', 
                'MPEG4SD480p-MPEG2SD480p', 
                "runtime/avcd-3/700", 
                "SET:COMM_CONF=1;",
#                "SET:EGRESS=MP2_SD;SOURCE;DEST;BITRATE=1.2;PMT_PID=480;VID_PID=481;AUD1_PID=482;PROG_NUM=515",
                "SET:EGRESS=MP2_SD;SOURCE;DEST;BITRATE=4.5;PMT_PID=480;VID_PID=481;AUD1_PID=482;SCTE35=1;SCTE35_PID_START=800;PROG_NUM=515",
                "START"
    ],

    710 => [    '3.0.0.41963', 
                'MPEG4SD480p-MPEG2SD480p', 
                "runtime/avcd-3/710", 
                "SET:COMM_CONF=1;debug=0",
                "SET:ADD_NODE=reader;NAME=reader;src-audio1-codecs=AC3;reader-discontinuity-threshold-backward=0.65;src-port=5500;src-addr=234.1.1.10;reader-discontinuity-threshold-forward=0.65",
                "SET:ADD_NODE=avcd_decoder;NAME=decoder;nice-setting=-19;bp-threshold=100000",
                "SET:ADD_NODE=muxer;NAME=muxer;dst-program-id=515;dst-video-pid=481;dst-pmt-pid=480;dst-audio1-pid=482;bp-threshold=100000;mux-vbv-maxrate=4500;mux-audio-maxdelay=0.035;mux-audio-bitrate=400;mux-video-maxdelay=0.418",
                #"SET:ADD_NODE=deinterlace_filter;NAME=deinterlace;deinterlace=1;bp-threshold=100000",
                #"SET:ADD_NODE=scale_filter;NAME=scale;scale=528|480;bp-threshold=100000",
                "SET:ADD_NODE=autoscale_filter;NAME=autoscale;autoscale=528|480|4|3|expand;bp-threshold=100000",
                #####"SET:ADD_NODE=video_encoder;NAME=encoder;x264-trellis=0;x264-sar=4|3;x264-threads=8;x264-ref=3;width=528;x264-bitrate=3953;no-input-threshold=4;dst-video-codec=mpeg2;x264-vbv-maxrate=3953;x264-vbv-bufsize=1835;x264-rc-lookahead=30;height=480",
                "SET:ADD_NODE=video_encoder;NAME=encoder;x264-trellis=0;x264-sar=4|3;x264-threads=4;x264-ref=3;width=528;x264-min-keyint=15;x264-me=dia;x264-no-psnr=1;x264-partitions=all;x264-bitrate=3953;x264-8x8dct=0;no-input-threshold=4;dst-video-codec=mpeg2;x264-vbv-maxrate=3953;x264-b-adapt=1;x264-subme=2;x264-interlaced=1;x264-bframes=2;closed-caption-opt=SCTE20Convert;x264-no-cabac=0;x264-scenecut=40;x264-no-ssim=1;x264-aq-strength=0.7;x264-keyint=30;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=1835;x264-rc-lookahead=30;height=480",
                "SET:ADD_NODE=mcast_writer;NAME=writer;dst-port=5500;nice-setting=-15;output-delay=8;dst-addr=234.1.1.11;mux-vbv-maxrate=4500;bp-threshold=100000",
                "SET:WIRE=reader,decoder-481,muxer-482",
                "SET:WIRE=decoder,autoscale",
                #"SET:WIRE=decoder,scale",
                "SET:WIRE=muxer,writer",
                #"SET:WIRE=deinterlace,encoder",
                #"SET:WIRE=deinterlace,scale",
                #"SET:WIRE=deinterlace,autoscale",
                #"SET:WIRE=scale,encoder",
                "SET:WIRE=autoscale,encoder",
                "SET:WIRE=encoder,muxer",
                "START"
    ],
    880 => [    '3.0.0.41963', 
				'MPEG2SD480p-MPEG4SD480p', 
                "runtime/avcd-3/880", 
                "SET:COMM_CONF=1;",
                "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;PIPS=127.1.1.11:5500;PIPS_PMT_PID=1000;PIPS_PID=2000",
                #"SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS=127.1.1.11:5500;PIPS_PMT_PID=1000;PIPS_PID=2000",
                "START"
    ],
    890 => [    '3.0.0.41963', 
				'MPEG2HD1080i-MPEG4HD1080i',
                "runtime/avcd-3/890", 
                "SET:COMM_CONF=1;",
                #"SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PIPS=127.1.1.11:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3",
                "SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PIPS=234.1.1.12:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
#                "SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PIPS=234.1.1.12:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_PID=502",
                "START"
    ],
    900 => [    '3.0.0.41963', 
				'MPEG2HD720p-MPEG4HD720p',
                "runtime/avcd-3/900", 
                "SET:COMM_CONF=1;",
                #"SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PIPS=127.1.1.11:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3",
                "SET:EGRESS=MP4_720p;SOURCE;DEST;BITRATE=5.4;PIPS=234.1.1.12:5500;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;SCTE35=1;SCTE35_PID_START=800;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
                "START"
    ],

    #230000 => [    '3.0.0.41963', 
    #               'MPEGXSD480p-MPEG4SD480p', 
    #               "runtime/avcd-3/230000", 
    #               "SET:COMM_CONF=1;",
    #               "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=1.6;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;PIPS=234.1.1.82:5500;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
    #               "START"
    #],
    
    230000 => [    '3.0.0.41963',
                   'MPEGXSD480p-MPEG4SD480p',
                   "runtime/avcd-3/250000",
                   "SET:COMM_CONF=1;",
                   "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=2.5;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;PIPS=234.1.1.82:5500;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_PID=3001;AUD2_SRC_CODEC=ac3",
                   "START"
    ], 
    230100 => [    '3.0.0.41963', 
                   'MPEGXHD720p-MPEG4HD720p', 
                   "runtime/avcd-3/230100", 
                   "SET:COMM_CONF=1;",
                   "SET:EGRESS=MP4_720p;SOURCE;DEST;BITRATE=5.4;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;PIPS=234.1.1.82:5500;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
                   "START"
    ],
    230200 => [    '3.0.0.41963', 
                   'MPEGXHD1080i-MPEG4HD1080i', 
                   "runtime/avcd-3/230200", 
                   "SET:COMM_CONF=1;",
                   "SET:EGRESS=MP4_1080;SOURCE;DEST;BITRATE=5.4;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;AUD2_PID=3001;PIPS=234.1.1.82:5500;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_SRC_CODEC=ac3",
                   "START"
    ],
    260000 => [    '3.0.0.41963',
                   'MPEGXSD480p-MPEG4SD480p',
                   "runtime/avcd-3/260000",
                   "SET:COMM_CONF=1;",
                   "SET:EGRESS=MP4_SD;SOURCE;DEST;BITRATE=2.5;PMT_PID=1000;VID_PID=2000;AUD1_PID=3000;PIPS=234.1.1.82:5500;PIPS_PMT_PID=1000;PIPS_PID=2000;AUD1_SRC_CODEC=ac3;AUD2_PID=3001;AUD2_SRC_CODEC=ac3",
                   "START"
    ],     
    99000 => [  '3.0.0.41963', 
				'MPEG2HD1080i-MPEG4HD1080i',
                "runtime/avcd-3/99000", 
                "SET:COMM_CONF=1;",
                "SET:ADD_NODE=reader;NAME=reader;src-audio1-codecs=ac3;reader-discontinuity-threshold-backward=0.65;src-port=5500;src-addr=234.1.1.10;reader-discontinuity-threshold-forward=0.65",
                "SET:ADD_NODE=avcd_decoder;NAME=decoder;nice-setting=-19;bp-threshold=100000",
                "SET:ADD_NODE=muxer;NAME=muxer;dst-audio2-pid=3001;dst-video-pid=2000;mux-vbv-maxrate=2000;mux-audio-bitrate=406;mux-rap=1;dst-pmt-pid=1000;mux-audio-maxdelay=0.040;dst-audio1-pid=3000;no-extra-desc=1;bp-threshold=100000",
                "SET:ADD_NODE=telecine_filter;NAME=pip_telecine;bp-threshold=100000;hard-telecine=1",
                "SET:ADD_NODE=video_encoder;NAME=encoder;x264-trellis=0;x264-sar=1|1;x264-threads=8;x264-ref=3;width=1920;x264-min-keyint=15;x264-me=dia;x264-no-psnr=1;x264-partitions=all;x264-speed-bufsize=90;x264-bitrate=1511;no-input-threshold=4;x264-8x8dct=1;dst-video-codec=avc;x264-vbv-maxrate=1511;x264-b-adapt=1;x264-subme=2;x264-interlaced=1;x264-bframes=2;x264-no-cabac=0;x264-speed=1.1;x264-scenecut=40;x264-no-ssim=1;x264-aq-strength=0.7;x264-keyint=30;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=1511;x264-rc-lookahead=30;height=1080",
                "SET:ADD_NODE=mcast_writer;NAME=writer;dst-port=5500;output-delay=8;dst-addr=234.1.1.11;mux-vbv-maxrate=2000;bp-threshold=100000",
                "SET:ADD_NODE=deinterlace_filter;NAME=pip_deinterlace;deinterlace=1;bp-threshold=100000",
                "SET:ADD_NODE=autoscale_filter;NAME=pip_autoscale;autoscale=192|192|4|3|expand;bp-threshold=100000",
                "SET:ADD_NODE=video_encoder;NAME=pip_encoder;x264-trellis=1;x264-sar=4|3;x264-threads=3;x264-ref=2;width=192;x264-min-keyint=15;x264-me=hex;x264-partitions=all;x264-bitrate=245;x264-8x8dct=0;no-input-threshold=4;x264-vbv-maxrate=245;x264-b-adapt=1;x264-subme=5;x264-bframes=16;closed-caption-opt=None;x264-scenecut=5;x264-keyint=30;x264-aq-strength=1.0;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=245;x264-rc-lookahead=15;height=192",
                "SET:ADD_NODE=muxer;NAME=pip_muxer;video-pcrs-only=1;scte35-strip=1;af-max-time=0.030;dst-video-pid=2000;mux-vbv-maxrate=300;dst-pmt-pid=1000;no-extra-desc=1;bp-threshold=100000",
                "SET:ADD_NODE=mcast_writer;NAME=pip_writer;dst-port=5500;dst-addr=127.1.1.11;mux-vbv-maxrate=300",

                "SET:ADD_NODE=autoscale_filter;NAME=foo_autoscale;autoscale=300|200|4|3|expand;bp-threshold=100000",
                "SET:ADD_NODE=video_encoder;NAME=foo_encoder;x264-trellis=1;x264-sar=4|3;x264-threads=3;x264-ref=2;width=300;x264-min-keyint=15;x264-me=hex;x264-partitions=all;x264-bitrate=2000;x264-8x8dct=0;no-input-threshold=4;x264-vbv-maxrate=2000;x264-b-adapt=1;x264-subme=5;x264-bframes=16;closed-caption-opt=None;x264-scenecut=5;x264-keyint=30;x264-aq-strength=1.0;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=2000;x264-rc-lookahead=15;height=200",
                "SET:ADD_NODE=muxer;NAME=foo_muxer;dst-audio1-pid=3000;dst-video-pid=2000;mux-vbv-maxrate=2000;mux-audio-bitrate=406;mux-rap=1;dst-pmt-pid=1000;mux-audio-maxdelay=0.040;no-extra-desc=1;bp-threshold=100000",
                "SET:ADD_NODE=mcast_writer;NAME=foo_writer;dst-port=5500;dst-addr=234.1.1.12;mux-vbv-maxrate=3000",

                "SET:ADD_NODE=autoscale_filter;NAME=boo_autoscale;autoscale=800|600|4|3|expand;bp-threshold=100000",
                "SET:ADD_NODE=video_encoder;NAME=boo_encoder;x264-trellis=1;x264-sar=4|3;x264-threads=3;x264-ref=2;width=800;x264-min-keyint=15;x264-me=hex;x264-partitions=all;x264-bitrate=3000;x264-8x8dct=0;no-input-threshold=4;x264-vbv-maxrate=3000;x264-b-adapt=1;x264-subme=5;x264-bframes=16;closed-caption-opt=None;x264-scenecut=5;x264-keyint=30;x264-aq-strength=1.0;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=3000;x264-rc-lookahead=15;height=600",
                "SET:ADD_NODE=muxer;NAME=boo_muxer;dst-audio1-pid=3000;dst-video-pid=2000;mux-vbv-maxrate=3000;mux-audio-bitrate=406;mux-rap=1;dst-pmt-pid=1000;mux-audio-maxdelay=0.040;no-extra-desc=1;bp-threshold=100000",
                "SET:ADD_NODE=mcast_writer;NAME=boo_writer;dst-port=5500;dst-addr=234.1.1.13;mux-vbv-maxrate=4000",

                "SET:ADD_NODE=autoscale_filter;NAME=goo_autoscale;autoscale=1200|900|4|3|expand;bp-threshold=100000",
                "SET:ADD_NODE=video_encoder;NAME=goo_encoder;x264-trellis=1;x264-sar=4|3;x264-threads=3;x264-ref=2;width=1200;x264-min-keyint=15;x264-me=hex;x264-partitions=all;x264-bitrate=3000;x264-8x8dct=0;no-input-threshold=4;x264-vbv-maxrate=3000;x264-b-adapt=1;x264-subme=5;x264-bframes=16;closed-caption-opt=None;x264-scenecut=5;x264-keyint=30;x264-aq-strength=1.0;bp-threshold=100000;x264-aud=1;x264-vbv-bufsize=3000;x264-rc-lookahead=15;height=900",
                "SET:ADD_NODE=muxer;NAME=goo_muxer;dst-audio1-pid=3000;dst-video-pid=2000;mux-vbv-maxrate=3000;mux-audio-bitrate=406;mux-rap=1;dst-pmt-pid=1000;mux-audio-maxdelay=0.040;no-extra-desc=1;bp-threshold=100000",
                "SET:ADD_NODE=mcast_writer;NAME=goo_writer;dst-port=5500;dst-addr=234.1.1.14;mux-vbv-maxrate=4000",


                "SET:WIRE=reader,decoder-481,muxer-482",
                "SET:WIRE=decoder,pip_telecine,encoder",
                "SET:WIRE=muxer,writer",
                "SET:WIRE=pip_telecine,pip_deinterlace",
                "SET:WIRE=encoder,muxer",

                "SET:WIRE=pip_deinterlace,pip_autoscale",
                "SET:WIRE=pip_autoscale,pip_encoder",
                "SET:WIRE=pip_encoder,pip_muxer",
                "SET:WIRE=pip_muxer,pip_writer",

                "SET:WIRE=pip_deinterlace,foo_autoscale",
                "SET:WIRE=foo_autoscale,foo_encoder",
                "SET:WIRE=foo_encoder,foo_muxer",
                "SET:WIRE=foo_muxer,foo_writer",

                "SET:WIRE=pip_deinterlace,boo_autoscale",
                "SET:WIRE=boo_autoscale,boo_encoder",
                "SET:WIRE=boo_encoder,boo_muxer",
                "SET:WIRE=boo_muxer,boo_writer",

                "SET:WIRE=pip_deinterlace,goo_autoscale",
                "SET:WIRE=goo_autoscale,goo_encoder",
                "SET:WIRE=goo_encoder,goo_muxer",
                "SET:WIRE=goo_muxer,goo_writer",


                "START"
    ],
    );
                
sub inittests
{
    my @channelsetlist = (	
        #1080i channels first
        "TLC_East_HD,236.1.254.21,320,590",
        "The_Travel_Channel_East_HD,236.1.254.47,320,590",
        "E_East_HD,236.1.254.35,320,590",
        "NFL_Network_East_HD,236.1.254.8,320,590",
        "Palladia_East_HD,236.1.254.7,320,590",
        "NBC Sports Network East HD,236.1.254.5,320,590",
        "Lifetime Movie East HD,236.1.254.11,320,590",
        "Animal_Planet_East_HD,236.1.254.22,320,590",
        "The_Science_Channel_East_HD,236.1.254.23,320,590",
        "Discovery_East_HD,236.1.254.20,320,590",
        "Showtime_East_HD,236.1.254.13,320,590",
        "TMC_East_HD,236.1.254.14,320,590",
        "Starz_East_HD,236.1.254.15,320,590",
        "Starz_Kids_Family_East_HD,236.1.254.16,320,590",
        "HUB_East_HD,236.1.254.38,320,590",
        "Velocity_East_HD,236.1.254.19,320,590",
        "Food_Network_East_HD,236.1.254.9,320,590",
        "HGTV_East_HD,236.1.254.10,320,590",
        "Universal_East_HD,236.1.254.12,320,590",
        "Destination_America_East_HD,236.1.254.24,320,590",
        "CNBC_East_HD,236.1.254.36,320,590",
        "USA_Network_East_HD,236.1.254.27,320,590",
        "Showtime_Showcase_East_HD,236.1.254.29,320,590",
        "Golf_Channel_East_HD,236.1.254.30,320,590",
        "SyFy_East_HD,236.1.254.31,320,590",
        "Sho_Too_East_HD,236.1.254.32,320,590",
        "Lifetime_East_HD,236.1.254.33,320,590",
        "Investigation_Discovery_East_HD,236.1.254.34,320,590",
        "Bravo_East_HD,236.1.254.37,320,590",
        "Outdoor_Channel_East_HD,236.1.254.41,320,590",


        # 720p next
        "ESPN_Alt_1_East_HD,236.1.254.100,210,600",
        "ESPN_Alt_2_East_HD,236.1.254.101,210,600",
        "ESPN_Alt_3_East_HD,236.1.254.102,210,600",
        "ESPN_Alt_4_East_HD,236.1.254.103,210,600",
        "ESPN_2_Alt_1_East_HD,236.1.254.104,210,600",
        "ESPN_2_Alt_2_East_HD,236.1.254.105,210,600",
        "ESPN_2_Alt_3_East_HD,236.1.254.106,210,600",
        "ESPN_2_Alt_4_East_HD,236.1.254.107,210,600",
        "National_Geographic_East_HD,236.1.254.6,210,600",
        "History_East_HD,236.1.254.42,210,600",
        "A_E_East_HD,236.1.254.1,210,600",
        "ESPN_East_HD,236.1.254.2,210,600",
        "ESPN2_East_HD,236.1.254.3,210,600",
        "ESPN_News_East_HD,236.1.254.4,210,600",
        "ESPN_U_East_HD,236.1.254.28,210,600",
        "Speed_East_HD,236.1.254.45,210,600",

        # more 1080i
        "MSNBC_East_HD,236.1.254.39,320,590",
        "Oxygen_East_HD,236.1.254.48,320,590",




        # 720p downconverts
        "Fox_Deportes_East_SD,236.0.254.115,210,585",
        "Fuel_East_SD,236.0.254.49,210,585",
        "National_Geographic_East_SD,236.1.254.6,210,580",
        "Fox_Movie_Channel_East_SD,236.0.254.98,210,580",
        "Speed_East_SD,236.1.254.45,210,585",
        "FX_East_SD,236.1.254.46,210,580",
        "FX_West_SD,236.0.254.54,210,580",
        "Fox_Soccer_Channel_East_SD,236.0.254.100,210,585",
        "Nat_Geo_Wild_East_SD,236.0.254.40,210,580",
        "Big_Ten_Network_East_SD,236.4.255.11,210,585",

        );

my @allbshe = ( 
        # all BSHE
        "Lifetime_Movie_Network_East_HD,236.1.254.11,,580",
        "Investigation_Discovery_East_HD,236.1.254.34,,580",
        "Hallmark_Movie_Channel_East_SD,236.0.254.118,,580",
        "History_East_SD,236.0.254.188,,580",
        "Travel_Channel_East_SD,236.0.254.192,,580",
        "Disney_Junior_East_SD,236.0.254.200,,580",
        "A_E_East_SD,236.0.254.51,,580",
        "Travel_Channel_West_SD,236.0.255.34,,580",
        "Hallmark_Channel_East_SD,236.0.255.59,,580",
        "TR3S_East_SD,236.0.254.130,,580",
        "MTV_Hits_East_SD,236.0.254.133,,580",
        "MTV2_East_SD,236.0.254.134,,580",
        "Cooking_Channel_East_SD,236.0.254.187,,580",
        "Logo_East_SD,236.0.254.65,,580",
        "DIY_East_SD,236.0.254.73,,580",
        "Food_Network_East_SD,236.0.254.97,,580",
        "Oprah_Winfrey_Network_West_SD,236.0.255.35,,580",
        "Great_American_Country_East_SD,236.0.254.104,,580",
        "HGTV_East_SD,236.0.254.116,,580",
        "HGTV_West_SD,236.0.254.120,,580",
        "CMT_Pure_Country_East_SD,236.0.254.124,,580",
        "TeenNick_East_SD,236.0.254.137,,580",
        "Nick_Jr_East_SD,236.0.254.141,,580",
        "MTV_Jams_East_SD,236.0.254.143,,580",
        "Food_Network_West_SD,236.0.254.186,,580",
        "Nickelodeon_West_SD,236.0.254.121,,580",
        "Nicktoons_East_SD,236.0.254.140,,580",
        "Comedy_Central_West_SD,236.0.254.144,,580",
        "Spike_TV_East_SD,236.0.254.164,,580",
        "VH1_Classic_East_SD,236.0.254.199,,580",
        "CMT_West_SD,236.0.254.64,,580",
        "Comedy_Central_East_SD,236.0.254.71,,580",
        "MTV_West_SD,236.0.255.49,,580",
        "QVC_East_SD,236.0.254.145,,580",
        "TV_Land_East_SD,236.0.254.195,,580",
        "CMT_East_SD,236.0.254.72,,580",
        "Spike_TV_West_SD,236.0.255.50,,580",
        "TV_Land_West_SD,236.0.255.51,,580",
        "VH1_Soul_East_SD,236.0.255.53,,580",
        "VH1_West_SD,236.0.255.54,,580",
        "Lifetime_West_SD,236.0.254.103,,580",
        "Lifetime_Real_Women_East_SD,236.0.254.105,,580",
        "Lifetime_Movie_Network_East_SD,236.0.254.126,,580",
        "Lifetime_East_SD,236.0.254.127,,580",
        "A_E_West_SD,236.0.254.180,,580",
        "History_West_SD,236.0.254.189,,580",
        "Military_History_East_SD,236.0.254.35,,580",
        "History_en_Espanol_East_SD,236.0.254.36,,580",
        "Animal_Planet_East_HD,236.1.254.22,,580",
        "E_East_HD,236.1.254.35,,580",
        "Starz_East_HD,236.1.254.15,,580",
        "Science_East_HD,236.1.254.23,,580",
        "Starz_West_HD,236.4.255.3,,580",
        "Universal_East_HD,236.1.254.12,,580",
        "Starz_Kids_Family_East_HD,236.1.254.16,,580",
        "Military_Channel_East_SD,236.0.254.128,,580",
        "Science_East_SD,236.0.254.185,,580",
        "Discovery_Familia_East_SD,236.0.254.34,,580",
        "BBC_America_East_SD,236.0.254.56,,580",
        "Destination_America_East_SD,236.0.254.78,,580",
        "The_HUB_East_SD,236.0.254.79,,580",
        "Investigation_Discovery_East_SD,236.0.254.80,,580",
        "BBC_World_News_East_SD,236.0.255.32,,580",
        "Discovery_en_Espanol_East_SD,236.0.254.107,,580",
        "Telemundo_West_SD,236.0.254.119,,580",
        "Mun2_East_SD,236.0.254.135,,580",
        "Telemundo_East_SD,236.0.254.177,,580",
        "CNBC_World_East_SD,236.0.254.31,,580",
        "Bravo_East_SD,236.0.254.60,,580",
        "Discovery_Fit_and_Health_East_SD,236.0.254.95,,580",
        "Wealth_TV_East_SD,236.0.255.209,,580",
        "Showtime_East_SD,236.0.254.148,,580",
        "Sho_Extreme_East_SD,236.0.254.150,,580",
        "Sho_Family_East_SD,236.0.254.152,,580",
        "Sho_Next_East_SD,236.0.254.153,,580",
        "Sho_2_East_SD,236.0.254.156,,580",
        "The_Movie_Channel_East_SD,236.0.254.183,,580",
        "Chiller_East_SD,236.0.254.39,,580",
        "FLIX_East_SD,236.0.254.96,,580",
        "Sho_Women_East_SD,236.0.254.158,,580",
        "The_Movie_Channel_Xtra_East_SD,236.0.254.184,,580",
        "Sho_Beyond_East_SD,236.0.254.42,,580",
        "Showtime_Showcase_East_SD,236.0.254.43,,580",
        "ABC_Family_East_SD,236.0.254.112,,580",
        "TBN_East_SD,236.0.254.193,,580",
        "BET_East_SD,236.0.254.57,,580",
        "Disney_Channel_East_SD,236.0.254.81,,580",
        "BET_Gospel_East_SD,236.0.255.36,,580",
        "Centric_East_SD,236.0.255.37,,580",
        "BET_West_SD,236.0.255.48,,580",
        "The_Weather_Channel_East_SD,236.0.255.57,,580",
        "Showtime_East_HD,236.1.254.13,,580",
        "The_Movie_Channel_East_HD,236.1.254.14,,580",
        "Destination_America_East_HD,236.1.254.24,,580",
        "Food_Network_East_HD,236.1.254.9,,580",
        "HGTV_East_HD,236.1.254.10,,580",
        "Showtime_Showcase_East_HD,236.1.254.29,,580",
        "Oprah_Winfrey_Network_East_SD,236.0.254.77,,580",
        "Sho_2_East_HD,236.1.254.32,,580",
        "HSN_East_SD,236.0.254.154,,580",
        "G4_East_SD,236.0.254.47,,580",
        "Animal_Planet_East_SD,236.0.254.55,,580",
        "C-SPAN_East_SD,236.0.254.74,,580",
        "C-SPAN2_East_SD,236.0.254.75,,580",
        "MTV_East_SD,236.0.254.132,,580",
        "Nickelodeon_East_SD,236.0.254.139,,580",
        "E_East_SD,236.0.254.173,,580",
        "Style_East_SD,236.0.254.176,,580",
        "VH1_East_SD,236.0.254.198,,580",
        "C-SPAN3_East_SD,236.0.254.38,,580",
        "Sprout_East_SD,236.0.254.52,,580",
        "Bravo_West_SD,236.0.254.61,,580",
        "A_E_East_HD,236.1.254.1,,580",
        "NBC_Sports_Network_East_HD,236.1.254.5,,580",
        "TLC_East_SD,236.0.254.182,,580",
        "Disney_Channel_West_SD,236.0.254.109,,580",
        "Syfy_East_SD,236.0.254.146,,580",
        "CLOO_East_SD,236.0.254.159,,580",
        "Golf_Channel_East_SD,236.0.254.179,,580",
        "USA_Network_East_SD,236.0.254.196,,580",
        "USA_Network_West_SD,236.0.254.197,,580",
        "Starz_West_SD,236.0.254.166,,580",
        "Indieplex_East_SD,236.0.254.44,,580",
        "Movieplex_East_SD,236.0.254.45,,580",
        "Retroplex_East_SD,236.0.254.46,,580",
        "Encore_West_SD,236.0.254.84,,580",
        "Encore_Family_West_SD,236.0.255.40,,580",
        "Starz_Cinema_West_SD,236.0.255.42,,580",
        "Starz_Kids_Family_West_SD,236.0.255.43,,580",
        "Oprah_Winfrey_Network_East_HD,236.4.255.18,,580",
        "BBC_America_East_HD,236.4.255.42,,580",
        "ABC_News_Now_East_SD,236.0.254.122,,580",
        "MTV2_West_SD,236.0.254.129,,580",
        "Biography_East_SD,236.0.254.178,,580",
        "ESPN_Classic_East_SD,236.0.254.92,,580",
        "ESPNews_East_SD,236.0.254.93,,580",
        "Logo_West_SD,236.0.255.38,,580",
        "MTVU_East_SD,236.0.255.52,,580",
        "H2_East_SD,236.0.254.117,,580",
        "Disney_XD_West_SD,236.0.254.125,,580",
        "Outdoor_Channel_East_SD,236.0.254.142,,580",
        "Showtime_Showcase_West_SD,236.0.254.155,,580",
        "Disney_XD_East_SD,236.0.254.190,,580",
        "SoapNet_West_SD,236.0.254.67,,580",
        "SoapNet_East_SD,236.0.255.62,,580",
        "Showtime_West_SD,236.0.254.149,,580",
        "Sho_Extreme_West_SD,236.0.254.151,,580",
        "Sho_2_West_SD,236.0.254.157,,580",
        "FLIX_West_SD,236.0.254.48,,580",
        "Sho_Next_West_SD,236.0.254.53,,580",
        "Sho_Beyond_West_SD,236.0.255.46,,580",
        "The_Movie_Channel_West_SD,236.0.255.58,,580",
        "The_Movie_Channel_Xtra_West_SD,236.0.255.61,,580",
        "The_HUB_East_HD,236.1.254.38,,580",
        "Mun2_West_SD,236.0.254.111,,580",
        "Encore_Action_West_SD,236.0.254.114,,580",
        "ShopNBC_East_SD,236.0.254.32,,580",
        "NFL_Network_East_SD,236.0.255.44,,580",
        "Starz_In_Black_East_SD,236.0.254.170,,580",
        "Starz_Kids_Family_East_SD,236.0.254.171,,580",
        "Encore_East_SD,236.0.254.83,,580",
        "Encore_Action_East_SD,236.0.254.85,,580",
        "Encore_Drama_East_SD,236.0.254.86,,580",
        "Encore_Love_East_SD,236.0.254.87,,580",
        "Encore_Suspense_East_SD,236.0.254.88,,580",
        "Encore_Family_East_SD,236.0.254.89,,580",
        "Starz_East_SD,236.0.254.165,,580",
        "Starz_Cinema_East_SD,236.0.254.167,,580",
        "Starz_Comedy_East_SD,236.0.254.168,,580",
        "Starz_Edge_East_SD,236.0.254.169,,580",
        "Encore_Westerns_East_SD,236.0.254.90,,580",
        "Sho_Women_West_SD,236.0.254.41,,580",
        "Sho_Family_West_SD,236.0.255.60,,580",
        "ABC_Family_West_SD,236.0.254.113,,580",
        "NBC_Sports_Network_East_SD,236.0.254.172,,580",
        "NBC_Sports_Network_Alt_1_East_SD,236.0.255.45,,580",
        "NBC_Sports_Network_Alt_2_East_SD,236.0.255.47,,580",
        "NHL_Network_East_SD,236.4.255.16,,580",
        "National_Geographic_East_HD,236.1.254.6,,580",
        "Fox_Soccer_Channel_East_SD,236.0.254.100,,580",
        "Nat_Geo_Wild_East_SD,236.0.254.40,,580",
        "Fuel_TV_East_SD,236.0.254.49,,580",
        "FX_West_SD,236.0.254.54,,580",
        "Fox_Movie_Channel_East_SD,236.0.254.98,,580",
        "Speed_East_SD,236.1.254.45,,580",
        "FX_East_SD,236.1.254.46,,580",
        "National_Geographic_East_SD,236.1.254.6,,580",
        "Fox_Deportes_East_SD,236.0.254.115,,580",
        "Fox_Business_Network_East_SD,236.0.254.160,,580",
        "Disney_Junior_West_SD,236.0.254.201,,580",
        "Fox_College_Sports_Central_SD,236.0.254.33,,580",
        "Fox_College_Sports_Atlantic_SD,236.0.254.50,,580",
        "Fox_News_Channel_East_SD,236.0.254.99,,580",
        "Fox_College_Sports_Pacific_SD,236.0.255.106,,580",
        "TVN_PPV_Event_East_SD,236.1.254.50,,580",
        "Velocity_East_HD,236.1.254.19,,580",
        "NFL_Network_East_HD,236.1.254.8,,580",
        "MSNBC_East_SD,236.0.254.131,,580",
        "Crime_Investigation_East_SD,236.0.254.37,,580",
        "CNBC_East_SD,236.0.254.66,,580",
        "Discovery_Channel_East_SD,236.0.254.76,,580",
        "SBN_East_SD,236.0.254.82,,580",
        "USA_Network_East_HD,236.1.254.27,,580",
        "Lifetime_East_HD,236.1.254.33,,580",
        "Syfy_East_HD,236.1.254.31,,580",
        "Bravo_East_HD,236.1.254.37,,580",
        "CNBC_East_HD,236.1.254.36,,580",
        "MSNBC_East_HD,236.1.254.39,,580",
        "Golf_Channel_East_HD,236.1.254.30,,580",
        "Palladia_East_HD,236.1.254.7,,580",
        "Oxygen_East_SD,236.0.254.138,,580",
        "Syfy_West_SD,236.0.254.147,,580",
        "MAVTV_East_SD,236.0.254.58,,580",
        "EWTN_East_SD,236.0.255.56,,580",
        "AXS_TV_East_HD,236.4.255.1,,580",
        "HDNet_Movies_East_HD,236.4.255.2,,580",
        "TV_Japan_East_SD,236.4.254.1,,580",
        "Playboy_East_SD,236.4.254.2,,580",
        "Tennis_Channel_East_SD,236.4.254.3,,580",
        "Discovery_Channel_East_HD,236.1.254.20,,580",
        "TLC_East_HD,236.1.254.21,,580",
        "Outdoor_Channel_East_HD,236.1.254.41,,580",
        "History_East_HD,236.1.254.42,,580",
        "Oxygen_East_HD,236.1.254.48,,580",
        "NBC_Sports_Network_Alt_1_East_HD,236.1.254.43,,580",
        "NBC_Sports_Network_Alt_2_East_HD,236.1.254.44,,580",
        "Speed_East_HD,236.1.254.45,,580",
        "FX_East_HD,236.1.254.46,,580",
        "GSN_East_HD,236.4.255.43,,580",
        "Biography_East_HD,236.4.255.14,,580",
        "Indieplex_East_HD,236.4.255.50,,580",
        "Retroplex_East_HD,236.4.255.51,,580",
        "Discovery_Channel_West_SD,236.0.254.110,,580",
        "Animal_Planet_West_SD,236.0.255.31,,580",
        "TLC_West_SD,236.0.255.33,,580",
        "Fox_Soccer_Channel_East_HD,236.0.254.100,,580",
        "Nat_Geo_Wild_East_HD,236.0.254.40,,580",
        "Fox_Business_Network_East_HD,236.4.255.35,,580",
        "Travel_Channel_East_HD,236.1.254.47,,580",
        "NHL_Network_East_HD,236.4.255.16,,580",
        "ESPN_East_HD,236.1.254.2,,580",
        "ESPN2_East_HD,236.1.254.3,,580",
        "ESPNU_East_HD,236.1.254.28,,580",
        "ESPNews_East_HD,236.1.254.4,,580",
        "ESPN_Alt_1_East_HD,236.1.254.100,,580",
        "ESPN_Alt_2_East_HD,236.1.254.101,,580",
        "ESPN_Alt_3_East_HD,236.1.254.102,,580",
        "ESPN_Alt_4_East_HD,236.1.254.103,,580",
        "ESPN2_Alt_1_East_HD,236.1.254.104,,580",
        "ESPN2_Alt_2_East_HD,236.1.254.105,,580",
        "ESPN2_Alt_3_East_HD,236.1.254.106,,580",
        "ESPN2_Alt_4_East_HD,236.1.254.107,,580",
        "ESPNU_East_SD,236.0.254.106,,580",
        "ESPN_East_SD,236.0.254.91,,580",
        "ESPN2_East_SD,236.0.254.94,,580",
        "ESPN_Alt_1_East_SD,236.0.255.201,,580",
        "ESPN_Alt_2_East_SD,236.0.255.202,,580",
        "ESPN_Deportes_East_SD,236.0.254.108,,580",
        "ESPN_Alt_3_East_SD,236.0.255.203,,580",
        "ESPN_Alt_4_East_SD,236.0.255.204,,580",
        "ESPN2_Alt_1_East_SD,236.0.255.205,,580",
        "ESPN2_Alt_2_East_SD,236.0.255.206,,580",
        "ESPN2_Alt_3_East_SD,236.0.255.207,,580",
        "ESPN2_Alt_4_East_SD,236.0.255.208,,580",
        "CBS_Sports_Network_East_HD,236.4.255.5,,580",
        "Hallmark_Channel_West_HD,236.4.255.6,,580",
        "Style_East_HD,236.4.255.10,,580",
        "G4_East_HD,236.4.255.4,,580",
        "MGM_East_HD,236.4.255.7,,580",
        "Starz_Edge_East_HD,236.4.255.8,,580",
        "Big_Ten_Network_East_HD,236.4.255.11,,580",
        "Starz_Comedy_East_HD,236.4.255.9,,580",
        "CTI_East_SD,236.4.254.10,,580",
        "SBTN_East_SD,236.4.254.7,,580",
        "TFC_East_SD,236.4.254.8,,580",
        "TVK_East_SD,236.4.254.9,,580",
        "Fox_News_Channel_East_HD,236.1.254.40,,580",
        "GSN_East_SD,236.4.254.4,,580",
        "CCTV4_East_SD,236.4.254.5,,580",
        "MYX_East_SD,236.4.254.6,,580",
        "Big_Ten_Network_East_SD,236.4.255.11,,580",
        "Hallmark_Channel_East_HD,236.4.255.15,,580",
        "Smithsonian_East_HD,236.4.255.17,,580",
        "Starz_Comedy_West_SD,236.4.254.12,,580",
        "Starz_Edge_West_SD,236.4.254.13,,580",
        "Starz_in_Black_West_SD,236.4.254.14,,580",
        "Encore_Suspense_West_SD,236.4.254.15,,580",
        "Encore_Drama_West_SD,236.4.254.16,,580",
        "Encore_Westerns_West_SD,236.4.254.17,,580",
        "Encore_Love_West_SD,236.4.254.18,,580",
        "MAVTV_East_HD,236.4.255.12,,580",
        "Tennis_Channel_East_HD,236.4.255.13,,580",
        "HBO_LA_East_SD,236.0.240.37,,580",
        "HBO_Caribbean_LA_East_SD,236.0.240.38,,580",
        "HBO_Family_LA_East_SD,236.0.240.40,,580",
        "Cinemax_LA_East_SD,236.0.240.65,,580",
        "MAX_Prime_LA_East_SD,236.0.240.67,,580",
        "RFD_TV_East_SD,236.0.240.72,,580",
        "HBO_East_SD_TDS,236.4.254.23,,580",
        "PPV_Slate_Channel_SD,236.0.254.194,,580",
        "5-Star_MAX_East_SD_TDS,236.4.254.19,,580",
        "Cinemax_West_SD_TDS,236.4.254.22,,580",
        "HBO_West_SD_TDS,236.4.254.24,,580",
        "HBO_Zone_East_SD_TDS,236.4.254.29,,580",
        "HBO_2_West_SD_TDS,236.4.254.31,,580",
        "OuterMAX_East_SD_TDS,236.4.254.33,,580",
        "ThrillerMAX_East_SD_TDS,236.4.254.36,,580",
        "Halogen_East_SD,236.4.254.42,,580",
        "ActionMAX_East_SD_TDS,236.4.254.20,,580",
        "Cinemax_East_SD_TDS,236.4.254.21,,580",
        "HBO_Comedy_East_SD_TDS,236.4.254.25,,580",
        "HBO_Family_East_SD_TDS,236.4.254.26,,580",
        "HBO_Latino_East_SD_TDS,236.4.254.27,,580",
        "HBO_Signature_East_SD_TDS,236.4.254.28,,580",
        "HBO_2_East_SD_TDS,236.4.254.30,,580",
        "MoreMAX_East_SD_TDS,236.4.254.32,,580",
        "Discovery_Channel_LA_East_SD,236.0.240.2,,580",
        "Discovery_Turbo_LA_East_SD,236.0.240.3,,580",
        "Discovery_Civilization_LA_East_SD,236.0.240.4,,580",
        "Discovery_Science_LA_East_SD,236.0.240.5,,580",
        "Discovery_Kids_LA_East_SD,236.0.240.57,,580",
        "Animal_Planet_LA_East_SD,236.0.240.58,,580",
        "Discovery_Home_Health_LA_East_SD,236.0.240.6,,580",
        "Discovery_Travel_Leisure_LA_East_SD,236.0.240.7,,580",
        "HBO_Comedy_East_HD_TDS,236.4.255.24,,580",
        "HBO_Zone_East_HD_TDS,236.4.255.30,,580",
        "HBO_East_HD_TDS,236.4.255.26,,580",
        "HBO_West_HD_TDS,236.4.255.27,,580",
        "HBO_2_East_HD_TDS,236.4.255.23,,580",
        "HBO_Signature_East_HD_TDS,236.4.255.29,,580",
        "HBO_Family_East_HD_TDS,236.4.255.25,,580",
        "HBO_Latino_East_HD_TDS,236.4.255.28,,580",
        "Cinemax_East_HD_TDS,236.4.255.21,,580",
        "MoreMAX_East_HD_TDS,236.4.255.33,,580",
        "ActionMAX_East_HD_TDS,236.4.255.20,,580",
        "Comedy_Central_East_HD,236.4.255.60,,580",
        "Gulfcom_CBC_East_SD,236.0.240.20,,580",
        "Gulfcom_Fox_WSVN_East_HD,236.0.240.24,,580",
        "Gulfcom_PBS_WBPT_East_SD,236.0.240.25,,580",
        "Gulfcom_WB_WPIX_East_SD,236.0.240.26,,580",
        "Gulfcom_UPN_WWOR_East_SD,236.0.240.27,,580",
        "Gulfcom_CITYTV_East_SD,236.0.240.29,,580",
        "Warner_Channel_LA_East_SD,236.0.240.34,,580",
        "Sony_Entertainment_LA_East_SD,236.0.240.36,,580",
        "HBO_Plus_LA_East_SD,236.0.240.39,,580",
        "MTV_Hits_LA_East_SD,236.0.240.52,,580",
        "MTV_LA_East_SD,236.0.240.53,,580",
        "Nickelodeon_LA_East_SD,236.0.240.54,,580",
        "VH1_LA_East_SD,236.0.240.55,,580",
        "Sony_Spin_East_SD,236.0.240.71,,580",
        "Univision_East_SD,236.4.255.65,,580",
        "Galavision_East_HD,236.4.255.71,,580",
        "Gulfcom_CBC_East_HD,236.0.240.20,,580",
        "Gulfcom_Fox_WSVN_East_HD,236.0.240.24,,580",
        "MAX_LA_East_HD,236.0.240.66,,580",
        "MTV_East_HD,236.4.255.52,,580",
        "TCM_LA_East_SD_Logic,236.0.240.74,,580",
        "Cartoon_Network_LA_East_SD_Logic,236.0.240.75,,580",
        "Boomerang_LA_East_SD_Logic,236.0.240.76,,580",
        "CNN_International_LA_East_SD_Logic,236.0.240.78,,580",
        "HLN_LA_East_SD_Logic,236.0.240.79,,580",
        "CNN_Espanol_LA_East_SD_Logic,236.0.240.80,,580",
        "Space_LA_East_SD_Logic,236.0.240.81,,580",
        "GMC_East_SD,236.0.241.1,,580",
        "Spike_East_HD,236.4.255.55,,580",
        "Nickelodeon_East_HD,236.4.255.58,,580",
        "VH1_East_HD,236.4.255.59,,580",
        "TV_Land_East_HD,236.4.255.63,,580",
        "QVC_East_HD,236.0.254.145,,580",
        "DIY_East_HD,236.9.13.154,,580",
        "Fuel_TV_East_HD,236.0.254.49,,580",
        "Cooking_Channel_East_HD,236.9.13.153,,580",
        "Fox_Movie_Channel_East_HD,236.0.254.98,,580",
        "CMT_East_HD,236.4.255.72,,580",
        "Space_LA_East_HD_Logic,236.0.240.77,,580",
        "MTV2_East_HD,236.4.255.73,,580",
        "Gulfcom_CTV_East_HD,236.0.240.82,,580",
        "Nick_Jr_LA_East_SD,236.0.240.83,,580",
        "MTV_Jams_LA_East_SD,236.0.240.84,,580",
        "Current_TV_East_SD,236.4.254.132,,580",
        "Ovation_East_SD,236.4.254.63,,580",
        "HRTV_East_SD,236.4.254.65,,580",
        "Youtoo_East_SD,236.4.254.66,,580",
        "CNN_East_SD_Logic,236.4.255.79,,580",
        "Wealth_TV_East_HD,236.4.255.74,,580",
        "BET_East_HD,236.4.255.75,,580",
        "Crime_Investigation_East_HD,236.4.255.76,,580",
        "H2_East_HD,236.4.255.77,,580",
        "VH1_Classics_LA_East_SD,236.0.240.85,,580",
        "VH1_Megahits_LA_East_SD,236.0.240.86,,580",
        "Comedy_Central_LA_East_SD,236.0.240.87,,580",
        "One_Caribbean_TV_East_SD,236.4.254.68,,580",
        "Epix_East_HD,236.4.255.78,,580",
        "CNN_East_HD_Logic,236.4.255.79,,580",
        "Hallmark_Movie_Channel_East_HD,236.4.255.80,,580",
        "Encore_West_HD,236.4.255.22,,580",
        "Gulfcom_CW_WGN_East_SD,236.0.240.88,,580",
        "CNN_International_LA_East_SD,236.0.240.10,,580",
        "TNT_LA_East_SD,236.0.240.11,,580",
        "Cartoon_Network_LA_East_SD,236.0.240.12,,580",
        "TruTV_LA_East_SD,236.0.240.13,,580",
        "Boomerang_LA_East_SD,236.0.240.14,,580",
        "Tooncast_LA_East_SD,236.0.240.15,,580",
        "ISAT_LA_East_SD,236.0.240.16,,580",
        "HLN_LA_East_SD,236.0.240.17,,580",
        "Space_LA_East_SD,236.0.240.18,,580",
        "TCM_LA_East_SD,236.0.240.19,,580",
        "LORAC_One_Caribbean_Weather_East_SD,236.0.240.28,,580",
        "Bloomberg_LA_East_SD,236.0.240.30,,580",
        "AXN_LA_East_SD,236.0.240.35,,580",
        "HBO_Plus_LA_West_SD,236.0.240.42,,580",
        "TBS_LA_East_SD,236.0.240.56,,580",
        "Tempo_East_SD,236.0.240.61,,580",
        "HBO_Signature_LA_East_SD,236.0.240.62,,580",
        "HBO_2_LA_West_SD,236.0.240.63,,580",
        "MAX_Prime_LA_West_SD,236.0.240.64,,580",
        "LIV_LA_East_SD,236.0.240.8,,580",
        "JCTV_East_SD,236.0.241.2,,580",
        "CNN_East_SD,236.0.241.5,,580",
        "TEN_Xtsy_East_SD,236.4.254.38,,580",
        "TEN_Juicy_East_SD,236.4.254.39,,580",
        "TEN_XX5_East_SD,236.4.254.40,,580",
        "Smile_of_a_Child_East_SD,236.4.254.43,,580",
        "Africa_Channel_East_SD,236.4.254.44,,580",
        "TBN_Enlace_East_SD,236.4.254.45,,580",
        "Blackbelt_TV_East_SD,236.4.254.46,,580",
        "Bravo_West_HD,236.4.255.38,,580",
        "SyFy_West_HD,236.4.255.40,,580",
        "USA_Network_West_HD,236.4.255.39,,580",
        "Oxygen_West_HD,236.4.255.41,,580",
        "Centric_Caribbean_East_SD,236.0.241.6,,580",
        "The_Church_Channel_East_SD,236.4.254.62,,580",
        "World_Harvest_Television_East_SD,236.4.254.50,,580",
        "CBS_Sports_Network_East_SD,236.4.254.51,,580",
        "NFL_Red_Zone_East_HD,236.4.255.19,,580",
        "AMC_West_SD,236.4.254.52,,580",
        "AMC_East_SD,236.4.254.53,,580",
        "WE_tv_West_SD,236.4.254.54,,580",
        "WE_tv_East_SD,236.4.254.55,,580",
        "IFC_East_SD,236.4.254.56,,580",
        "Sundance_Channel_West_SD,236.4.254.57,,580",
        "Sundance_Channel_East_SD,236.4.254.58,,580",
        "AMC_East_HD,236.4.255.44,,580",
        "WE_tv_East_HD,236.4.255.45,,580",
        "IFC_East_HD,236.4.255.46,,580",
        "Sportsman_Channel_East_SD,236.4.254.41,,580",
        "NFL_Red_Zone_East_SD,236.0.255.41,,580",
        "3ABN_East_SD,236.0.240.1,,580",
        "Bloomberg_East_SD,236.4.254.37,,580",
        "Sorpresa_East_SD,236.4.254.48,,580",
        "La_Familia_Cosmovision_East_SD,236.4.254.49,,580",
        "LORAC_ABC_WPLG_East_SD,236.0.240.21,,580",
        "Encore_East_HD,236.4.255.22,,580",
        "LORAC_NBC_WTVJ_East_SD,236.0.240.23,,580",
        "LORAC_ABC_WPLG_East_HD,236.0.240.21,,580",
        "LORAC_CBS_WFOR_East_HD,236.0.240.73,,580",
        "LORAC_NBC_WTVJ_East_HD,236.0.240.23,,580",
        "Sundance_West_SD,236.4.254.57,,580",
        "Sundance_East_SD,236.4.254.58,,580",
        "IFC_West_SD,236.4.254.67,,580",
        "Nickelodeon_West_HD,236.4.255.53,,580",
        "VH1_West_HD,236.4.255.54,,580",
        "Comedy_Central_West_HD,236.4.255.56,,580",
        "MTV_West_HD,236.4.255.57,,580",
        "Spike_West_HD,236.4.255.61,,580",
        "TV_Land_West_HD,236.4.255.64,,580",
        "UniMas_East_HD,236.4.255.66,,580",
        "Univision_West_HD,236.4.255.67,,580",
        "UniMas_West_HD,236.4.255.68,,580",
        "NBC_East_HD,236.4.255.69,,580",
        "NBC_West_HD,236.4.255.70,,580",
);

my @allsports = ( 
        # all sports
        "NBC_Sports_Network_East_HD,236.1.254.5,,580",
        "Golf_Channel_East_SD,236.0.254.179,,580",
        "ESPN_Classic_East_SD,236.0.254.92,,580",
        "ESPNews_East_SD,236.0.254.93,,580",
        "NFL_Network_East_SD,236.0.255.44,,580",
        "NBC_Sports_Network_East_SD,236.0.254.172,,580",
        "NBC_Sports_Network_Alt_1_East_SD,236.0.255.45,,580",
        "NBC_Sports_Network_Alt_2_East_SD,236.0.255.47,,580",
        "NHL_Network_East_SD,236.4.255.16,,580",
        "Fox_Soccer_Channel_East_SD,236.0.254.100,,580",
        "Fox_College_Sports_Central_SD,236.0.254.33,,580",
        "Fox_College_Sports_Atlantic_SD,236.0.254.50,,580",
        "Fox_College_Sports_Pacific_SD,236.0.255.106,,580",
        "NFL_Network_East_HD,236.1.254.8,,580",
        "NBC_Sports_Network_Alt_1_East_HD,236.1.254.43,,580",
        "NBC_Sports_Network_Alt_2_East_HD,236.1.254.44,,580",
        "Fox_Soccer_Channel_East_HD,236.0.254.100,,580",
        "NHL_Network_East_HD,236.4.255.16,,580",
        "ESPN_East_HD,236.1.254.2,,580",
        "ESPN2_East_HD,236.1.254.3,,580",
        "ESPNU_East_HD,236.1.254.28,,580",
        "ESPNews_East_HD,236.1.254.4,,580",
        "ESPN_Alt_1_East_HD,236.1.254.100,,580",
        "ESPN_Alt_2_East_HD,236.1.254.101,,580",
        "ESPN_Alt_3_East_HD,236.1.254.102,,580",
        "ESPN_Alt_4_East_HD,236.1.254.103,,580",
        "ESPN2_Alt_1_East_HD,236.1.254.104,,580",
        "ESPN2_Alt_2_East_HD,236.1.254.105,,580",
        "ESPN2_Alt_3_East_HD,236.1.254.106,,580",
        "ESPN2_Alt_4_East_HD,236.1.254.107,,580",
        "ESPNU_East_SD,236.0.254.106,,580",
        "ESPN_East_SD,236.0.254.91,,580",
        "ESPN2_East_SD,236.0.254.94,,580",
        "ESPN_Alt_1_East_SD,236.0.255.201,,580",
        "ESPN_Alt_2_East_SD,236.0.255.202,,580",
        "ESPN_Deportes_East_SD,236.0.254.108,,580",
        "ESPN_Alt_3_East_SD,236.0.255.203,,580",
        "ESPN_Alt_4_East_SD,236.0.255.204,,580",
        "ESPN2_Alt_1_East_SD,236.0.255.205,,580",
        "ESPN2_Alt_2_East_SD,236.0.255.206,,580",
        "ESPN2_Alt_3_East_SD,236.0.255.207,,580",
        "ESPN2_Alt_4_East_SD,236.0.255.208,,580",
        "CBS_Sports_Network_East_HD,236.4.255.5,,580",
        "CBS_Sports_Network_East_SD,236.4.254.51,,580",
        "NFL_Red_Zone_East_HD,236.4.255.19,,580",
        "NFL_Red_Zone_East_SD,236.0.255.41,,580",
);
    if(0)
    {
        my $test = 200000;
        foreach my $channelset (@channelsetlist)
        {
            foreach my $key (keys %{$avcdtests{200000}})
            {
                $avcdtests{$test}->{$key} = $avcdtests{200000}->{$key};
            }
            my ($name, $srcaddr, $configpreset) = split(/,/, $channelset);
            # here we'll poke in values for the various channels
            #$avcdtests{$test} = $avcdtests{200000};
            $avcdtests{$test}->{id} = $test;
            $avcdtests{$test}->{configpreset} = $configpreset;
            $avcdtests{$test}->{name} = "BSHE HD - $name - $srcaddr";
            $avcdtests{$test}->{"--src-addr"} = $srcaddr;
            $avcdtests{$test}->{"--src-port"} = 5500;
            $avcdtests{$test}->{"--dst-addr"} = "234.1.1.11";
            $avcdtests{$test}->{"--dst-port"} = 5500;
            $test += 10;
        }

    
    my $test = 210000;
    foreach my $channelset (@channelsetlist)
    {
        foreach my $key (keys %{$avcdtests{210000}})
        {
            $avcdtests{$test}->{$key} = $avcdtests{210000}->{$key};
        }
        my ($name, $srcaddr, $configpreset, $autopreset) = split(/,/, $channelset);
        # here we'll poke in values for the various channels
        #$avcdtests{$test} = $avcdtests{200000};
        $avcdtests{$test}->{id} = $test;
        $avcdtests{$test}->{configpreset} = $autopreset;# TODO FIX THIS$configpreset;
        $avcdtests{$test}->{name} = "BSHE[auto-hook-on] - $name - $srcaddr";
        $avcdtests{$test}->{"--src-addr"} = $srcaddr;
        $avcdtests{$test}->{"--src-port"} = 5500;
        $avcdtests{$test}->{"--dst-addr"} = "234.1.1.11";
        $avcdtests{$test}->{"--dst-port"} = 5500;
        $test += 10;
    }
    }
    if(0)
    {
    my $test = 220000;
    foreach my $channelset (@channelsetlist)
    {
        foreach my $key (keys %{$avcdtests{220000}})
        {
            $avcdtests{$test}->{$key} = $avcdtests{220000}->{$key};
        }
        my ($name, $srcaddr, $configpreset, $autopreset) = split(/,/, $channelset);
        # here we'll poke in values for the various channels
        #$avcdtests{$test} = $avcdtests{200000};
        $avcdtests{$test}->{id} = $test;
        $avcdtests{$test}->{configpreset} = $autopreset;# TODO FIX THIS$configpreset;
        $avcdtests{$test}->{name} = "BSHE[auto-hook-on w/SAP] - $name - $srcaddr";
        $avcdtests{$test}->{"--src-addr"} = "234.1.1.10";#$srcaddr;
        $avcdtests{$test}->{"--src-port"} = 5500;
        $avcdtests{$test}->{"--dst-addr"} = "234.1.1.11";
        $avcdtests{$test}->{"--dst-port"} = 5500;
        $test += 10;
    }
    }
    my $test = 230000;
    #foreach my $channelset (@channelsetlist)
    {

        # cycle through the sources, identify what's there for resolution and audio eses
        # configure test params accordingly i.e. if SD, and 192k Eng, 192k Spa in source,
        # check for AC-3, AC-3 audio es
        # todo, identify source res and audio eses, sass? and we need to do this at test fireup
        # or metadata read
        # sample src.txt file
        # mpeg2video|width=704|height=480
        # ac3|language=eng
        # ac3|language=spa

        opendir(FH, "streams/bshe");
        my $file = ""; my @srcs;
        do
        {
            $file = readdir FH;
            push @srcs, $file if($file && $file =~ /\.dump/);
        }while($file);
        closedir FH;

        foreach my $src (sort @srcs)
        {
            foreach my $key (keys %{$avcdtests{230000}})
            {
                $avcdtests{$test}->{$key} = $avcdtests{230000}->{$key};
            }
            $avcdtests{$test}->{wantedegresses} = "h264";

            my $file = $src;
            $file =~ s/\.dump/\.txt/;
            if(open(FH, "streams/bshe/$file"))
            {
                my @codecs = <FH>;
                close FH;
                # for this testing we want ac-3 audio, pri, sec
                my $autopreset;
                my $audioeses = 0;
                foreach my $codec (@codecs)
                {
                    chomp $codec;
                    if($codec)
                    {
                        my @d = split(/\|/, $codec);
                        if($d[0] eq "mpeg2video" || $d[0] eq "h264")
                        {
                            $d[2] =~ m/height=(\d+)/;
                            if($1 == 480)
                            {
                                $autopreset = 230000;
                                $d[1] =~ m/width=(\d+)/;
                                if(0)#$1 == 544)# || $1 == 720)
                                {
                                    $avcdtests{$test}->{wantedsar}="107:88";
                                    $avcdtests{$test}->{wanteddar}="107:80";
                                }
                                else
                                {
                                    $avcdtests{$test}->{wantedsar}="40:33";
                                    $avcdtests{$test}->{wanteddar}="4:3";
                                }
                                $avcdtests{$test}->{wantedwidth}=528;
                                $avcdtests{$test}->{wantedheight}=480;
                                $avcdtests{$test}->{wanteddeinterlace}=1;
                                $avcdtests{$test}->{wantedinterlace}=0;
                            }
                            elsif($1 == 720)
                            {
                                $autopreset = 230100;
                                $avcdtests{$test}->{wantedsar}="1:1";
                                $avcdtests{$test}->{wanteddar}="16:9";
                                $avcdtests{$test}->{wantedwidth}=1280;
                                $avcdtests{$test}->{wantedheight}=720;
                                $avcdtests{$test}->{wanteddeinterlace}=0;
                                $avcdtests{$test}->{wantedinterlace}=0;
                            }
                            elsif($1 == 1080)
                            {
                                $autopreset = 230200;
                                $d[1] =~ m/width=(\d+)/;
                                if($1 == 1440)
                                {
                                    $avcdtests{$test}->{wantedsar}="4:3";
                                    $avcdtests{$test}->{wanteddar}="16:9";
                                    $avcdtests{$test}->{wantedwidth}=1440;
                                }
                                else
                                {
                                    $avcdtests{$test}->{wantedsar}="1:1";
                                    $avcdtests{$test}->{wanteddar}="16:9";
                                    $avcdtests{$test}->{wantedwidth}=1920;
                                }
                                $avcdtests{$test}->{wantedheight}=1080;
                                $avcdtests{$test}->{wanteddeinterlace}=0;
                                $avcdtests{$test}->{wantedinterlace}=0;
                            }
                            elsif($1 == 1088)
                            {
                                $autopreset = 230200;
                                $avcdtests{$test}->{wantedsar}="1:1";
                                $avcdtests{$test}->{wanteddar}="30:17";
                                $avcdtests{$test}->{wantedwidth}=1920;
                                $avcdtests{$test}->{wantedheight}=$1;
                                $avcdtests{$test}->{wanteddeinterlace}=0;
                                $avcdtests{$test}->{wantedinterlace}=0;
                            }
                        }

                        if($audioeses < 2 && ($d[0] eq "ac-3" || $d[0] eq "ac3"))
                        {
                            ++$audioeses;
                            if($d[1])
                            {
                                my ($desc, $lang) = split(/=/, $d[1]);
                                $avcdtests{$test}->{wantedegresses} .= ",".$d[0];
                                $avcdtests{$test}->{wantedegresses} .= "-".$lang if($lang);
                            }
                            else
                            {
                                $avcdtests{$test}->{wantedegresses} .= ",".$d[0];
                            }
                        }
                    }
                }
                my @p = split(/\-/, $src);
                #my ($name, $srcaddr, $configpreset, $autopreset) = split(/,/, $channelset);
                # here we'll poke in values for the various channels
                #$avcdtests{$test} = $avcdtests{200000};
                $avcdtests{$test}->{id} = $test;
                if(!$autopreset)
                {
                    ;#print "\ninittests(): Error! No preset determined.";
                    #exit 1;
                }
                $avcdtests{$test}->{configpreset} = $autopreset;
                $avcdtests{$test}->{name} = "BSHE[SD/HD SAP/PIP] - $p[0]";#name - $srcaddr";
                $avcdtests{$test}->{"--src-addr"} = "234.1.1.10";#$srcaddr;
                $avcdtests{$test}->{"--src-port"} = 5500;
                $avcdtests{$test}->{"--dst-addr"} = "234.1.1.11";
                $avcdtests{$test}->{"--dst-port"} = 5500;
                $avcdtests{$test}->{"srcfile"} = "bshe/$src";
                $avcdtests{$test}->{"--dst-port"} = 5500;
                my @pids = (0,1000,2000,3000,8191);
                push @pids, 3001 if($audioeses > 1);
                $avcdtests{$test}->{wantedpids} = ([@pids]);
            }
            $test += 10;
        }

    }
    my $test = 240000;
    #foreach my $channelset (@channelsetlist)
    {

        # cycle through the sources, identify what's there for resolution and audio eses
        # configure test params accordingly i.e. if SD, and 192k Eng, 192k Spa in source,
        # check for AC-3, AC-3 audio es
        # todo, identify source res and audio eses, sass? and we need to do this at test fireup
        # or metadata read
        # sample src.txt file
        # mpeg2video|width=704|height=480
        # ac3|language=eng
        # ac3|language=spa

        opendir(FH, "streams/bshe");
        my $file = ""; my @srcs;
        do
        {
            $file = readdir FH;
            push @srcs, $file if($file && $file =~ /\.dump/);
        }while($file);
        closedir FH;

        foreach my $src (sort @srcs)
        {
            foreach my $key (keys %{$avcdtests{240000}})
            {
                $avcdtests{$test}->{$key} = $avcdtests{240000}->{$key};
            }
            $avcdtests{$test}->{wantedegresses} = "h264";

            my $file = $src;
            $file =~ s/\.dump/\.txt/;
            if(open(FH, "streams/bshe/$file"))
            {
                my @codecs = <FH>;
                close FH;
                # for this testing we want ac-3 audio, pri, sec
                my $autopreset;
                my $audioeses = 0;
                foreach my $codec (@codecs)
                {
                    chomp $codec;
                    if($codec)
                    {
                        my @d = split(/\|/, $codec);
                        if($d[0] eq "mpeg2video" || $d[0] eq "h264")
                        {
                            $d[2] =~ m/height=(\d+)/;
                            $autopreset = 230000 if($1 == 480);
                            $autopreset = 230100 if($1 == 720);
                            $autopreset = 230200 if($1 == 1080 || $1 == 1088);
                        }

                        if($audioeses < 2 && ($d[0] eq "ac-3" || $d[0] eq "ac3"))
                        {
                            ++$audioeses;
                            if($d[1])
                            {
                                my ($desc, $lang) = split(/=/, $d[1]);
                                $avcdtests{$test}->{wantedegresses} .= ",".$d[0];
                                $avcdtests{$test}->{wantedegresses} .= "-".$lang if($lang);
                            }
                            else
                            {
                                $avcdtests{$test}->{wantedegresses} .= ",".$d[0];
                            }
                        }
                    }
                }
                my @p = split(/\-/, $src);
                #my ($name, $srcaddr, $configpreset, $autopreset) = split(/,/, $channelset);
                # here we'll poke in values for the various channels
                #$avcdtests{$test} = $avcdtests{200000};
                $avcdtests{$test}->{id} = $test;
                if(!$autopreset)
                {
                    ;#print "\ninittests(): Error! No preset determined.";
                    #exit 1;
                }
                $avcdtests{$test}->{configpreset} = $autopreset;
                $avcdtests{$test}->{name} = "BSHE[LIVE SD/HD SAP/PIP] - $p[0]";#name - $srcaddr";

                # get src addr from $file
                my @ps = split(/\-/, $file);
                my $octet = @ps[$#ps];
                $octet =~ s/\.txt//g;
                $avcdtests{$test}->{"--src-addr"} = $octet;
                $avcdtests{$test}->{"--src-port"} = 5500;
                $avcdtests{$test}->{"--dst-addr"} = "234.1.1.11";
                $avcdtests{$test}->{"--dst-port"} = 5500;
                $avcdtests{$test}->{"srcfile"} = "bshe/$src";
                $avcdtests{$test}->{"--dst-port"} = 5500;
                my @pids = (0,1000,2000,3000,8191);
                push @pids, 3001 if($audioeses > 1);
                $avcdtests{$test}->{wantedpids} = ([@pids]);
            }
            $test += 10;
        }

    }
    # DOWNCONVERTS added Sep 24, 15 - wow we have been avcding a long time
    my $test = 260000;
    {
        opendir(FH, "streams/bshe-downconverts");
        my $file = ""; my @srcs;
        do
        {
            $file = readdir FH;
            push @srcs, $file if($file && $file =~ /\.dump/);
        }while($file);
        closedir FH;

        foreach my $src (sort @srcs)
        {
            foreach my $key (keys %{$avcdtests{260000}})
            {
                $avcdtests{$test}->{$key} = $avcdtests{260000}->{$key};
            }
            $avcdtests{$test}->{wantedegresses} = "h264";

            my $file = $src;
            $file =~ s/\.dump/\.txt/;
            if(open(FH, "streams/bshe-downconverts/$file"))
            {
                my @codecs = <FH>;
                close FH;
                # for this testing we want ac-3 audio, pri, sec
                my $autopreset;
                my $audioeses = 0;
                foreach my $codec (@codecs)
                {
                    chomp $codec;
                    if($codec)
                    {
                        my @d = split(/\|/, $codec);
                        if($d[0] eq "mpeg2video" || $d[0] eq "h264")
                        {
                            $autopreset = 260000;
                            $avcdtests{$test}->{wantedsar}="40:33";
                            $avcdtests{$test}->{wanteddar}="4:3";
                            $avcdtests{$test}->{wantedwidth}=528;
                            $avcdtests{$test}->{wantedheight}=480;
                            $avcdtests{$test}->{wanteddeinterlace}=1;
                        }

                        if($audioeses < 2 && ($d[0] eq "ac-3" || $d[0] eq "ac3"))
                        {
                            ++$audioeses;
                            if($d[1])
                            {
                                my ($desc, $lang) = split(/=/, $d[1]);
                                $avcdtests{$test}->{wantedegresses} .= ",".$d[0];
                                $avcdtests{$test}->{wantedegresses} .= "-".$lang if($lang);
                            }
                            else
                            {
                                $avcdtests{$test}->{wantedegresses} .= ",".$d[0];
                            }
                        }
                    }
                }
                my @p = split(/\-/, $src);
                $avcdtests{$test}->{id} = $test;
                $avcdtests{$test}->{configpreset} = $autopreset;
                $avcdtests{$test}->{name} = "BSHE[SD DOWNCONVERT SAP/PIP] - $p[0]";#name - $srcaddr";
                $avcdtests{$test}->{"--src-addr"} = "234.1.1.10";#$srcaddr;
                $avcdtests{$test}->{"--src-port"} = 5500;
                $avcdtests{$test}->{"--dst-addr"} = "234.1.1.11";
                $avcdtests{$test}->{"--dst-port"} = 5500;
                $avcdtests{$test}->{"srcfile"} = "bshe-downconverts/$src";
                $avcdtests{$test}->{"--dst-port"} = 5500;
                my @pids = (0,1000,2000,3000,8191);
                push @pids, 3001 if($audioeses > 1);
                $avcdtests{$test}->{wantedpids} = ([@pids]);
            }
            $test += 10;
        }

    }



    if(0)
    {
        $test = 310000;
        my $atest = 210000;
        foreach my $channelset (@channelsetlist)
        {
            foreach my $key (keys %{$avcdtests{310000}})
            {
                $avcdtests{$test}->{$key} = $avcdtests{310000}->{$key};
            }
            my ($name, $srcaddr, $configpreset) = split(/,/, $channelset);
            # here we'll poke in values for the various channels
            #$avcdtests{$test} = $avcdtests{200000};
            $avcdtests{$test}->{id} = $test;
            $avcdtests{$test}->{configpreset} = $configpreset;
            $avcdtests{$test}->{name} = "BSHE[manual-test]: Validate $name";
            $avcdtests{$test}->{teststeps} = [("In another terminal run automated test \#$atest. Visually validate the channel performance.\n\tThere should be smooth, fluid frame presentation.","\n\tWait for a scene that presents horizontal panning or vertical scrolling of content, again fluid presentation should be seen.", "\n\tWait for a high motion or transitional span of content where the frame content changes dramatically, watch for blockiness, graininess.\n\tVerify Closed Captioning text is rendered on the STB.", "In a third terminal, run ts_tool.pl -a 234.1.1.11 Record 5s of the egress by hitting \'R\' and then \'Q\'. run mediainfo capture-1.ts, did you see an analysis of the egress?", "Verify the DAR (display aspect resolution), it should be 4:3 for 528x480 SD, and 16:9 for both HD profiles.", "Verify AC-3 audio via the mediainfo data on pid 3000.", "Verify H.264 level settings against the following table\n\t480p=High\@3.0\n\t720p=>High\@L3.2\n\t1080i=>High\@4.0")];

            $test += 10;
            $atest += 10;
        }
    }
    $test = 330000;
    my $atest = 230000;

    opendir(FH, "streams/bshe");
    my $file = ""; my @srcs;
    do
    {
        $file = readdir FH;
        push @srcs, $file if($file && $file =~ /\.dump/);
    }while($file);
    closedir FH;

    foreach my $src (sort @srcs)
    {
        my @p = split(/\-/, $src);

        foreach my $key (keys %{$avcdtests{330000}})
        {
            $avcdtests{$test}->{$key} = $avcdtests{330000}->{$key};
            $avcdtests{$test}->{id} = $test;
            $avcdtests{$test}->{runactions} = ['manualTest'],
            $avcdtests{$test}->{name} = "BSHE[manual SD/HD SAP/PIP] - $p[0]";
            $avcdtests{$test}->{teststeps} = [("In another terminal run automated test \#$atest. Visually validate the channel performance.\n\tThere should be smooth, fluid frame presentation.","\n\tWait for a scene that presents horizontal panning or vertical scrolling of content, again fluid presentation should be seen.", "\n\tWait for a high motion or transitional span of content where the frame content changes dramatically, watch for blockiness, graininess.\n\tVerify Closed Captioning text is rendered on the STB.", "In a third terminal, run ts_tool.pl -a 234.1.1.11 Record 5s of the egress by hitting \'R\' and then \'Q\'. run mediainfo capture-1.ts, did you see an analysis of the egress?", "Verify the DAR (display aspect resolution), it should be 4:3 for 528x480 SD, and 16:9 for both HD profiles.", "Verify AC-3 audio via the mediainfo data on pid 3000.", "Verify H.264 level settings against the following table\n\t480p=High\@3.0\n\t720p=>High\@L3.2\n\t1080i=>High\@4.0")];

        }
        $test += 10;
        $atest += 10;
    }
}

sub showtest
{
    my ($self) = @_;
    my ($jnk, $test) = split(/=/, $ARGV[2]);
    print "\n\n*******************************************************************************************\n";
    print "*******                Showing test => [".$avcdtests{$test}->{id}."] ".$avcdtests{$test}->{name}."\n";
    print "*******************************************************************************************\n";
    
    my ( $k, $v );
    while( ($k,$v) = each %{$avcdtests{$test}})
    {
        print $k." => ".$v."\n";
    };
}

sub runtests
{
    my ($packagename, $specifiedtests) = @_;
    my @params;
    my $prefix;
    my $failedtests = 0;
    my $tmp;
    #my $reportpath = cwd()."/results/$ARGV[0]";
    #my $summarypath = cwd()."/results/$ARGV[0]";
    my $reportpath = cwd() . "$main::resultsPath";
    my $summarypath = $reportpath;

    system("mkdir -p $packagename") if(! -e $packagename);
    system("mkdir -p $summarypath") if(! -e $summarypath);
    $main::Report->setreportpath($reportpath);
    $main::Summary->setsummarypath($summarypath);

    ($tmp, $specifiedtests) = split(/\=/, $specifiedtests);
    my @specifiedtestlist;
    if($specifiedtests =~ /\-/)
    {
        my @range = split(/\-/, $specifiedtests);
        for(my $i=$range[0];$i<=$range[1];$i+=10)
        {
            push @specifiedtestlist, $i;
        }
    }
    else
    {
        @specifiedtestlist = split(/,/, $specifiedtests);
    }

    foreach my $test (@specifiedtestlist)
    {
        if($specifiedtestlist[0] >= 200000 && $specifiedtestlist[0] <= 290000)
        {
            my $Test = new AvcdTests( $avcdtests{$test});
            $Test->{_testparams}->{'--src-addr'} = $avcdtests{$test}->{"--src-addr"};
            $Test->{_testparams}->{'--src-port'} = 5500;
            $Test->{_testparams}->{'--dst-addr'} = $avcdtests{$test}->{"--dst-addr"};
            $Test->{_testparams}->{'--dst-port'} = 5500;
            $Test->$func2;
        }
        else
        {
            my $Test = new AvcdTests( $avcdtests{$test} );
            $Test->$func2;
        }

    }
    return($failedtests);

}

sub batchModeLog
{
	my ($testID) = @_;
    &generic::stageout("INFO", "Batch mode testing: test $testID.");
	&generic::stageout("INFO", "Total tests to run: " . @{$avcdtests{$testID}->{testList}} );
	&generic::stageout("INFO", "Test cases: @{$avcdtests{$testID}->{testList}} ");
}

sub getTests
{
    &inittests();
	return( %avcdtests );
}
