#
# VERSION 3
#
# Korey O'Dell
package AvcdTests;
use strict;
use warnings;
use Data::Dumper;
use IO::Socket;
require testclass;
require report;
our @ISA = qw( TestClass );

use IPC::Run qw( run start harness timeout );
use Cwd;
use Sys::Statistics::Linux::Processes;	# Used for OS level statistics gathering
use IO::Select;							# Used for TS stream capture
use IO::Socket::Multicast;				# Used for TS stream capture

# Additional time functions for better precision, used in the 
# MPEGTS decoding routines
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep
        clock_gettime clock_getres clock_nanosleep clock stat );

use sigtrap 'handler' => \&AvcdTests::catchsignals, 'INT';
use sigtrap 'handler' => \&catchsignals, 'HUP';
use sigtrap 'handler' => \&catchsignals, 'TERM';

# a few globals for the various tests
#$AvcdTests::srcdstrecording{"timetorecord"} = 30;

my $memorystats;		# Memory statistics, from Sys.Statistics.Linux.Processes
my $processstats; 		# Process statistics, from Sys.Statistics.Linux.Processes
my %burst;
my %srcdstrecording;
my %loseinputstate;
my %loseinput;
my $s;					# Source socket, used to monitor ingress
my $d;					# Destination socket, used to monitor egress
my $sctePid;
my $tsPlay;				# The IPC::Run object of ts_play, to start and stop it
my $avcd;				# The IPC::Run object of avcd, to start and stop it
my @children;			# A list of forked sub processes
my @avcdtestparams; 	# Command line args, left for compatability from version2
my @avcdArgs;			# Command line args, new for version3

$srcdstrecording{"timetorecord"} = 30;
my $caughtsignal 	= 0;
my $debug 			= 0;	# Enables debugging output, for debugging the test harness
my %streamType		= ();	# A Xref of HEX stream types to human readable stream types
my %psiTables		= ();	# A Xref of HEX PSI tables to human readable tables
my %pids 			= ();	# All the pids available in a TS stream
my %pmt 			= ();	# Data from the PMT
my %pat 			= ();	# Data from the PAT
my $seenScte35Pids;
my %h;
my %streamInfo;
my %assetInfo;
$|++;
1;

# AvcdTests new();
#
# Creates a new AvcdTests object, inherits from TestClass (testclass.pm)
#
# Arguments: LIST
# Returns: AvcdTests
sub new
{
    my ($class) = shift;#$_[0]; 
    my $self = $class->SUPER::new( @_);#$_[1], $_[2], $_[3] );
    $self->{_testbinpath} = "/opt/avail/bin/avcd";
    $self->{_packagename} = "avcd-3";
    bless $self, $class;
    return $self;
}

# @scalar beta()
# 
# New to version 3, common code for many tests, impliments the new
# *action fields in the tests described in avcdtests hash from avcd.pm
#
# Arguments: none
# Returns: LIST
sub beta
{
    # See avcd.pm hash for complete info, details on this test.
    my ( $self ) 	= @_;							# This class
    my $failedtests = 0;							# Counter of failed tests
    my $testnumber 	= $self->{_testid};				# The unique test id number
    my $packagename = $self->{_packagename};		# The application, ie. avcd-3
    my $probTime	= time();
    
	@avcdArgs = ();

    gettestparams($self);
    #getavcdtestparams($self, 3);	# A list of input test parameters
    #print "\nDBG: beta(): \@avcdArgs = @avcdArgs\n";
    
    # Reset some global data structures, and start logging
    $self->starttest();
    $seenScte35Pids = "";
    %streamInfo = ();
    $self->{_runloop} = $self->{_testparams}->{runloop} if($self->{_testparams}->{runloop});
    # Get the pre-run, run, and post-run actions for the current test
	# Loop through the actions defined in the current test
	# The action routines need to return 1 or greater on success and 0 on failure
	foreach my $actionKey( '_prerunactions', '_startactions', '_runactions', '_postrunactions' )
	{
		my @actions;
		$self->addtestresults( " -- start $actionKey --" );

		# Make sure the $acktionKey is okay, if not end gracefully
		eval{ @actions = @{$self->{$actionKey}} };
		if( $@ )
		{
			my $msg = "FAILED: problem with '$actionKey'"; 
			$msg .= ( $actionKey !~ /^_/ ) ? " missing beginning underscore" : " check the spelling" ;
			$self->addtestresults( "$msg : $@" );
			zCleanUp( $self );
			return();				# This only gets called if _testmode eq 'batch'
		}
		
		# Don't want to run probeactions here, these methods are run 
		# in the forked process every X seconds.
		next if ( $actionKey eq 'probeactions' );

		# Loop through the list of actions, if the actionKey is runactions
		# then there is a possibility of more than one itteration
		# based on the $self->{_runloop} variable
		my $iterations = ( $actionKey eq '_runactions' ) ? $self->{_runloop} : 1 ;
        my $done = 0;
		for ( my $i = 1; $i <= $iterations && !$done ; $i++ )
		{
			$self->addtestresults( "******************************************************") if ( $actionKey eq '_runactions' );
			$self->addtestresults( "*** runactions loop $i of $iterations iterations" ) if ( $actionKey eq '_runactions' );
			$self->addtestresults( "******************************************************") if ( $actionKey eq '_runactions' );
			foreach my $action (@actions)
			{
				if( UNIVERSAL::isa( $action, 'ARRAY') )
				{
					my $a = \&{@$action[0]};
                    my $ret = $a->($self, @$action[1], @$action[2], @$action[3], @$action[4]);
					if( $ret <= 0 )
					{
						$self->{_testfailurescount} = 1 if($ret == 0);
                        $self->endtest();
					 	zCleanUp( $self );
					 	return();
					}

				} elsif( UNIVERSAL::isa( $action, 'HASH') ) 
				{
					# ToDo - add some useful code here
					
				} else {
					# Run the action sub routine, if it returns false 
					# gracefully fail.
                    my $ret = $self->$action();
                    if( $ret == -1 )
                    {
                        $done = 1;
                    }
                    elsif( $ret == 0 )
                    {
                        $self->{_testfailurescount} = 1;
                        $self->endtest();
                        zCleanUp( $self );
                        return();
                    }
				}
                if(defined $tsPlay)
                {
                    my $tsPlayPid = $tsPlay->{KIDS}[0]->{PID};
                    if($tsPlayPid)
                    {
                        my $res = kill 0=>$tsPlayPid;
                        $tsPlay->pump_nb if($res);
                    }
                }
			} # End of foreach $action
		} # End of for looping $iterations
		$self->addtestresults( " -- end $actionKey --" );

	} # End of foreach $actionKey
    &zCleanUp( $self );
    
    $self->endtest();
}



# Common things to probe for, need to make sure vairous
# programs are still running during the test
# PROTOTYPE, work in progress......., may need to fork this from
# here or somewhere else, to watch things as a background process
sub probe
{
	my ( $self ) = @_;
	my $probeTime;
	#if( $probTime && $actionKey eq '_runactions')
	if( $probeTime )
	{
		print( "\nDBG ------------- probeTime -------------------\n" );
		foreach my $probAction ( @_ )
		{
			$self->{_testfailurescount} = 1;
		 	zCleanUp( $self );
		 	return();
		}
	}
}

sub setupcapture
{
    my ($self, $addr, $port) = @_;
    my ( $s );
    my $msg = "setupcapture()";

	$s = IO::Socket::Multicast->new(
		LocalAddr	=> $addr,
        LocalPort	=> $port,
        ReuseAddr	=> 1,
        Blocking	=> 0
	);

	if( !defined($s) )
	{
		$self->addtestresults("$msg: Failed - can't create UDP socket: $@");
		return 0;
	}

	# Add a multicast group
    $s->mcast_add( $addr );
    $s->mcast_ttl(16);
    return(1, $s);
}

sub capturestream
{
    my ($self, $runtime, $s) = @_;
    # FUNCTION: Capture TS to a scalar. if $runtime is zero, perform in non-blocking fashion. 
    # NOTE: setupcapture() must be called before this func.
    $self->{_capture} = "";
    my $start = [gettimeofday];
    my %stream;
    $stream{"lowbr"} = 999;
    $stream{"lastaudiopid"} = [gettimeofday];

    my $sel = new IO::Select();
    $sel->add($s);

    my $msg;
    my $byte_buffer;
    my $rawbytesthissecond = 0;
    my $bytesthissecond = 0;
    my $tsbytes = 0;
    my $lastread;
    my $elapsed;
    do
    {
        my $t0 = [gettimeofday];
        my $t1;
        if( $s->recv($msg, 1316) )
        {
            $self->{_capture} .= $msg;
            $rawbytesthissecond += 1358;
            $tsbytes += 1316;
            $bytesthissecond += 1316;
            $stream{"bitssentthissecond"} += 1316*8;
            $stream{"packets"} += 7;
            
            # ok processed 7 ts packets, update stats
            $t1 = [gettimeofday];
            
            $lastread = $t1;
            $elapsed = tv_interval($start, $t1);
        }
        else
        {
            $t1 = [gettimeofday];
            $elapsed = tv_interval($start, $t1);
        }
    }while ($elapsed < $runtime);

    my $bitrate = sprintf("%.2f", ($tsbytes*8/$runtime/1000) / 1000 );
    return $bitrate;
}

sub validateIngressBrokenDelMe
{
   # NOTE broken currently, fix as validateEgress
	my ( $self ) = @_;
	# Setup the socket, get it ready for real time capture
	my ( $s ) = &setupcapture( $self );
    my ($bitrate) = &capturestream( $self, 1, $s );
    if( $bitrate > 0 )
    {
        $self->addtestresults( "Check AVCD ingress bitrate[$bitrate Mbps]: PASSED");    
        return 1;
    }
    else
    {
        $self->addtestresults( "Check AVCD ingress bitrate[$bitrate Mbps]: FAILED");    
        return 0;
    }
}

sub validateIngress
{
	my ( $self, $runtime ) = @_;
    $runtime = 1 if(! $runtime);

	# Setup the socket, get it ready for real time capture
	my ( $success, $d ) = &setupcapture( $self, 
                                         $self->{_testparams}->{"--src-addr"},
                                         $self->{_testparams}->{"--src-port"} );
    if($success)
    {
        my ($bitrate) = &capturestream($self, $runtime, $d );
        if( $bitrate > 0 )
        {
            $self->addtestresults( "validateIngress(): bitrate[$bitrate Mbps]: PASSED");    
            return 1;
        }
        else
        {
            $self->addtestresults( "validateIngress(): bitrate[$bitrate Mbps]: FAILED");    
            return 0;
        }
    }
    return 0;
}

sub ingressContains
{
	my ( $self ) = @_;
    my $ret = 0;
    my $file = "/tmp/ingress-".$self->{"ccport"}.".ts";
    if(-e "/usr/bin/ffprobe")
    {
        open(FH, ">$file");
        print FH $self->{_capture};
        close FH;

        #my %si;
        #&parsePackets($self->{_capture}, \%si);
        #print Dumper %si;





        my @lines = `ffprobe -show_streams $file 2>/dev/null`;
        #unlink $file;
        my $es = 0;
        my $stream;
        foreach my $line (@lines)
        {
            if($line =~ /\[STREAM\]/) # start section
            {
                ++$es;
            }
            if($line =~ /codec_name=(\w+)/)
            {
                $stream->{$es}->{codec} = $1;
            }
            if($line =~ /codec_type=(\w+)/)
            {
                $stream->{$es}->{codec_type} = $1;
            }
            if($line =~ /codec_name=(\w+\d+)/)
            {
                $stream->{$es}->{codec_name} = $1;
            }
            if($line =~ /language=(\w+)/)
            {
                $stream->{$es}->{language} = $1;
            }
            if($line =~ /width=(\d+)/)
            {
                $stream->{$es}->{width} = $1;
            }
            if($line =~ /height=(\d+)/)
            {
                $stream->{$es}->{height} = $1;
            }
        }
        foreach my $key (sort keys %{$stream})
        {
            if($stream->{$key}->{codec_type} eq "video")
            {
                $self->{ingress}->{video}->{$key}->{codec_name} = $stream->{$key}->{codec_name};
                $self->{ingress}->{video}->{$key}->{width} = $stream->{$key}->{width};
                $self->{ingress}->{video}->{$key}->{height} = $stream->{$key}->{height};
            }
            elsif($stream->{$key}->{codec_type} eq "audio")
            {
                $self->{ingress}->{audio}->{$key}->{codec_name} = $stream->{$key}->{codec_name};
                $self->{ingress}->{audio}->{$key}->{language} = $stream->{$key}->{language};
            }
        }
        my $info;
        foreach my $i (sort keys %{$self->{ingress}})
        {
            $info .= "[$i]: ";
            foreach my $key (sort keys %{$self->{ingress}->{$i}})
            {
                foreach my $k (keys %{$self->{ingress}->{$i}->{$key}})
                {
                    my $val;
                    $val = $self->{ingress}->{$i}->{$key}->{$k} ? $self->{ingress}->{$i}->{$key}->{$k} : "none";
                    $info .= "[$k]=".$val.", ";
                }
            }
        }
        $self->addtestresults( "ingressContains(): $info: PASSED");
        $ret = 1;
    }
    else
    {
        $self->addtestresults( "ingressContains(): no ffprobe program available: FAILED");    
    }
    return $ret;

    # old
    my $info;
    foreach my $i (keys %{$self->{ingress}})
    {
        foreach my $key (keys %{$self->{ingress}->{$i}})
        {
            $info .= "$i=$key=".$self->{ingress}->{$i}->{$key};
        }
    }
    $self->addtestresults( "ingressContains(): $info: PASSED");
    #$self->{ingressaudio} = $audio;
    return 1;

    if(-e "/usr/bin/mediainfo")
    {
        my $file = "/tmp/ingress-".$self->{"ccport"}.".ts";
        open(FH, ">$file");
        print FH $self->{_capture};
        close FH;
        my $audio = `mediainfo --Inform="Audio;%Format%" /tmp/ingress.ts`;
        chomp $audio;
        $self->addtestresults( "ingressContains(): \'$audio\' audio detected: PASSED");
        $self->{ingressaudio} = $audio;

        my $video = `mediainfo --Inform="Video;%Format%" /tmp/ingress.ts`;
        chomp $video;
        $self->addtestresults( "ingressContains(): \'$video\' video detected: PASSED");
        unlink "/tmp/ingress.ts";
    }
    else
    {
        $ret = 0;
        $self->addtestresults( "ingressContains(): no mediainfo program available: FAILED");    
    }
    return $ret;
}


sub validateEgress
{
	my ( $self, $runtime, $which ) = @_;
    $runtime = 1 if(! $runtime);
    if( (time - $self->{_testtimestart}) < 40) # 10s
    {
        return 1;
    }
    $which = $self->{_testparams}->{"--dst-addr"} if(! $which );

	# Setup the socket, get it ready for real time capture
	my ( $success, $d ) = &setupcapture( $self, 
                                         $which,
                                         $self->{_testparams}->{"--dst-port"} );
    if($success)
    {
        my ($bitrate) = &capturestream($self, $runtime, $d );
        if( $bitrate > 0 )
        {
            $self->addtestresults( "validateEgress(): bitrate[$bitrate Mbps] from $which : PASSED");    
            return 1;
        }
        else
        {
            $self->addtestresults( "validateEgress(): bitrate[$bitrate Mbps] from $which: FAILED");    
            return 0;
        }
    }
    return 0;
}

sub validateMux
{
    my ($self, $runtime, $profile) = @_;
    if( (time - $self->{_testtimestart}) < 40) # 10s
    {
        return 1;
    }
    $profile = "main" if ( ! $profile );
    my $tsbytes = 0;
    my $msg;
    my %stream;
    my %ccs;
    my $pid;
    my $mux;
    my $avg;
    my @bytes;
    my $p0; my $p1; my $p2; my $p3; my $af; my $sc; my $cc; my $ccerrors;
    eval
    {
        @bytes =  unpack "(C11 x177)*", $self->{_capture};
    };

    for(my $p=0; $p<scalar(@bytes); $p+=11)
    {
        $p0= $bytes[$p];
        $p1 = $bytes[$p+1];
        $p2 = $bytes[$p+2];
        $p3 = $bytes[$p+3];
        $p1 = $p1 & 0x1f;
        $pid = $p2 | ($p1 << 8);
        $cc = $p3;
        $af = ($cc >> 4) & 0x03;
        $sc = ($cc >> 6) & 0x03;
        $cc = $cc & 0x0f;
        $stream{$pid} += 188;
        
        if( exists $ccs{$pid} )
        {
            my $nextcc = $ccs{$pid} + 1;
            $nextcc = 0 if($nextcc > 15);
            if($cc != $nextcc && $pid != 8191 && $af != 0 && $af != 2)
            {
                ++$ccerrors;
            }
        }
        $ccs{$pid} = $cc;
    }

    # calc bitrates for each pid
    my @pids = sort keys %stream;
    my $failures = 0;
    foreach my $pid (@pids)
    {
        my $br = ($stream{$pid}*8/$runtime/1000) / 1000;

        ++$streamInfo{$profile}->{$pid}->{samples};
        $streamInfo{$profile}->{$pid}->{total} += $br;
        $streamInfo{$profile}->{$pid}->{avg} = 
            $streamInfo{$profile}->{$pid}->{total} / $streamInfo{$profile}->{$pid}->{samples};
        
        if( $pid != 8191)
        {
            if($br < ( $streamInfo{$profile}->{$pid}->{avg} / 3 ) )
            {
                $self->addtestresults( "validateMux(): FAILED ES[$pid] bitrate is too low [$br] avg [".$streamInfo{$profile}->{$pid}->{avg}."]");
                ++$failures;
            }
        }
        $mux .= $pid."[".sprintf("%.3f", $br)."] ";
        $avg .= $pid."[".sprintf("%.3f", $streamInfo{$profile}->{$pid}->{avg})."] ";
    }


    if($failures) # already logged the failures, return 0
    {
        return 0;
    }
    $self->addtestresults( "validateMux(): PASSED");    
    $self->addtestresults( "\tcurrent es bitrates: PASSED: $mux:");    
    $self->addtestresults( "\taverage es bitrates: PASSED: $avg:");    

    return 1;
}

sub validateH264
{
	my ( $self ) = @_;
    my $ret = 0;
    if( (time - $self->{_testtimestart}) < 40) # 10s
    {
        return 1
    }
    if(-e "/opt/avail/bin/h264_analyze")
    {
        if(-e "/opt/avail/bin/h264_analyze")
        {
            my $file = "/tmp/egress-".$self->{"ccport"}.".ts";
            unlink $file;
            my $h264file = "/tmp/egress-".$self->{"ccport"}.".h264";
            unlink $h264file;;
            open(FH, ">$file");
            print FH $self->{_capture};
            close FH;
            `ffmpeg -y -i $file -acodec copy -vcodec copy $h264file 2>/dev/null`;
            my @lines = `h264_analyze $h264file 2>/dev/null`;
            if($? == 0)
            {
                my $tip = 0; my $hpp = 0;
                foreach my $line (@lines)
                {
                    ++$tip if($line =~ /timing_info_present_flag : 1/);
                    ++$hpp if($line =~ /nal_hrd_parameters_present_flag : 0/);
                }
                if($tip && $hpp)
                {
                    $self->addtestresults( "validateH264(): PASSED: timing_info_present_flag=1 and nal_hrd_parameters_present_flag=0");
                    $ret = 1;
                }
                elsif(!$tip)
                {
                    $self->addtestresults( "validateH264(): FAILED: timing_info_present_flag != 1");
                }
                elsif(!$hpp)
                {
                    $self->addtestresults( "validateH264(): FAILED: nal_hrd_parameters_present_flag != 0");
                }
            }
            else
            {
                $self->addtestresults( "validateH264(): WARNING: h264_analyze segfaulted");
                return 1;
            }
        }
        else
        {
            $self->addtestresults( "validateH264(): FAILED: no ffmpeg available");
        }
    }
    else
    {
        $self->addtestresults( "validateH264(): FAILED: no h264_analyze available");
    }

    return $ret;
}

sub egressContains
{
	my ( $self, $acodec, $vcodec, $sar, $dar ) = @_;
    my $ret = 0; 
    my $failures = 0;
    if( (time - $self->{_testtimestart}) < 40) # 10s
    {
        return 1;
    }

    if(! $self->{_wantedegresses})
    {
        $self->addtestresults( "egressContains(): FAILED wantedegresses is empty.");
        return 0;
    }

    if(-e "/usr/bin/ffprobe")
    {
        my $file = "/tmp/egress-".$self->{"ccport"}.".ts";
        open(FH, ">$file");
        print FH $self->{_capture};
        close FH;
        my $cmd = "ffprobe -show_streams $file 2>/dev/null";
        my @lines = `$cmd`;
        my %streams;
        my $es = 0;
        foreach my $line (@lines)
        {
            if($line =~ /\[STREAM\]/) # start section
            {
                ++$es;
            }
            if($line =~ /codec_name=(\w+)/)
            {
                $streams{$es}->{codec} = $1;
            }
            if($line =~ /language=(\w+)/)
            {
                $streams{$es}->{language} = $1;
            }
            if($line =~ /width=(\d+)/)
            {
                $streams{$es}->{width} = $1;
            }
            if($line =~ /height=(\d+)/)
            {
                $streams{$es}->{height} = $1;
            }
            if($line =~ /sample_aspect_ratio=(\d*\:\d*)/)
            {
                $streams{$es}->{sample_aspect_ratio} = $1;
            }
            if($line =~ /display_aspect_ratio=(\d*\:\d*)/)
            {
                $streams{$es}->{display_aspect_ratio} = $1;
            }
        }
        my $codecs;
        my @keys = sort keys %streams;
        foreach my $key (@keys)
        {
            next if($streams{$key}->{codec} eq "unknown");
            $codecs .= $streams{$key}->{codec};
            $codecs .= (exists $streams{$key}->{language}) ? "-".$streams{$key}->{language} : "";
            $codecs .= "," if($key ne $keys[$#keys]);
        }
        my @wanted = split(/,/, $self->{_wantedegresses});
        my @codeclist = split(/,/, $codecs);
        my $found = 0;
        foreach my $w (@wanted)
        {
            ++$found if(&isin($w, @codeclist));
        }
        if($found == scalar(@wanted) )
        {
            $self->addtestresults( "egressContains(): PASSED wanted [".$self->{_wantedegresses}."] got [".$codecs."]");
            ++$ret;
        }
        else
        {
            $self->addtestresults( "egressContains(): FAILED wanted [".$self->{_wantedegresses}."] got [".$codecs."]");
            ++$failures;
        }
        # WIDTH / HEIGHT
        if($self->{_wantedwidth})
        {
            my $foundwidth=0;
            my $i;
            for($i=0;$i<=$es;++$i)
            {
                if(defined $streams{$i}->{width})
                {
                    ++$foundwidth;last;
                }
            }
            if($foundwidth && $streams{$i}->{width} == $self->{_wantedwidth})
            {
                $self->addtestresults( "egressContains(): PASSED wanted WIDTH [".$self->{_wantedwidth}."] got [".$streams{$i}->{width}."]");
                ++$ret;
            }
            else
            {
                $self->addtestresults( "egressContains(): FAILED wanted WIDTH [".$self->{_wantedwidth}."] got [".$streams{$i}->{width}."]");
                ++$failures;
            }

        }
        if($self->{_wantedheight})
        {
            my $foundheight=0;
            my $i;
            for($i=0;$i<=$es;++$i)
            {
                if(defined $streams{$i}->{height})
                {
                    ++$foundheight;last;
                }
            }
            if($foundheight && $streams{$i}->{height} == $self->{_wantedheight})
            {
                $self->addtestresults( "egressContains(): PASSED wanted HEIGHT [".$self->{_wantedheight}."] got [".$streams{$i}->{height}."]");
                ++$ret;
            }
            else
            {
                $self->addtestresults( "egressContains(): FAILED wanted HEIGHT [".$self->{_wantedheight}."] got [".$streams{$i}->{height}."]");
                ++$failures;
            }

        }


        $sar=$self->{_wantedsar} if($self->{_wantedsar});
        $dar=$self->{_wanteddar} if($self->{_wanteddar});
        # SAR / DAR
        if($sar)
        {
            my $foundsar=0;
            my $i;
            for($i=0;$i<=$es;++$i)
            {
                if(defined $streams{$i}->{sample_aspect_ratio})
                {
                    ++$foundsar;last;
                }
            }
            if($foundsar && $streams{$i}->{sample_aspect_ratio} eq $sar)
            {
                $self->addtestresults( "egressContains(): PASSED wanted SAR [".$sar."] got [".$streams{$i}->{sample_aspect_ratio}."]" );
                ++$ret;
            }
            else
            {
                $self->addtestresults( "egressContains(): FAILED wanted SAR [$sar] got [".$streams{$i}->{sample_aspect_ratio}."]");
                ++$failures;
            }
        }
        if($dar)
        {
            my $founddar=0;
            my $i;
            for($i=0;$i<=$es;++$i)
            {
                if(defined $streams{$i}->{display_aspect_ratio})
                {
                    ++$founddar;last;
                }
            }
            if($founddar && $streams{$i}->{display_aspect_ratio} eq $dar)
            {
                $self->addtestresults( "egressContains(): PASSED wanted DAR [".$dar."] got [".$streams{$i}->{display_aspect_ratio}."]" );
                ++$ret;
            }
            else
            {
                $self->addtestresults( "egressContains(): FAILED wanted DAR [$dar] got [".$streams{$i}->{display_aspect_ratio}."]");
                ++$failures;
            }
        }


    }

    $ret = 0 if($failures);
    return $ret;
    
    # NOT USED ANYMORE AND BROKEN, egress.ts needs to be  unique

    if(! $acodec) 
    {

        if($self->{ingressaudio})
        {
            $acodec = $self->{ingressaudio};
        }
        else
        {
            if($acodec eq "none")
            {
                ; # do nothing, not wanting to check for audio, pip
            }
            else
            {
                $self->addtestresults( "egressContains(): no audio codec specified: FAILED");
                return 0;
            }
        }
    }

    if(-e "/usr/bin/mediainfo")
    {
        open(FH, ">/tmp/egress.ts");
        print FH $self->{_capture};
        close FH;
        my $audio = `mediainfo --Inform="Audio;%Format%" /tmp/egress.ts`;
        chomp $audio;
        if($audio eq $acodec)
        {
            $self->addtestresults( "egressContains(): $acodec audio detected: PASSED");
        }
        else
        {
            $ret = 0;
            $self->addtestresults( "egressContains(): $audio audio detected, wanted $acodec: FAILED");
            rename "/tmp/egress.ts", "/tmp/failedaudio.ts";
        }
        my $video = `mediainfo --Inform="Video;%Format%" /tmp/egress.ts`;
        chomp $video;
        if($video eq $vcodec)
        {
            $self->addtestresults( "egressContains(): $vcodec video detected: PASSED");
        }
        else
        {
            $ret = 0;
            $self->addtestresults( "egressContains(): $video detected, wanted $vcodec: FAILED");    
        }
        unlink "/tmp/egress.ts" if($ret == 1); #save it if we failed
    }
    else
    {
        $ret = 0;
        $self->addtestresults( "egressContains(): no mediainfo program available: FAILED");    
    }
    return $ret;
}

sub egressContainsPids
{
	my ( $self, $pids, $noFail, $intermittentPids, $periodicity ) = @_;
    if( (time - $self->{_testtimestart}) < 40)
    {
        return 1;
    }
    if(! $pids)
    {
        $pids = $self->{_wantedpids};
    }
    my ($result, @pidsSeen) = &containsPids(\$self->{_capture}, $pids, \%h);
    my $ret = 1;
    if($result)
    {
        if($intermittentPids && $periodicity)
        {
            my ($result, $junk) = &containsPids(\$self->{_capture}, $intermittentPids, \%h);
            if($result)
            {
                $self->addtestresults( "\tegressContainsPids(): [".join(",", sort @$intermittentPids)."] : PASSED" );
            }
            else
            {
                $self->addtestresults( "\tegressContainsPids(): still looking" );
                if(++$h{"scans"} > $periodicity)
                {
                    $self->addtestresults( "\tegressContainsPids(): FAILED! never saw pids [".join(",", sort @$intermittentPids)."]" );
                    $ret = 0;
                    $h{"scans"} = 0;
                }
            }
        }
        else
        {
            if(scalar(@pidsSeen) != scalar(@$pids))
            {
                $self->addtestresults( "\tegressContainsPids(): FAILED! Extra pid seen. Pids seen [".join(",", sort @pidsSeen)."], wanted [".join(",", @$pids)."]"." DEBUG ".scalar(@pidsSeen)." and ".scalar(@$pids));
                $ret = 0;
            }
            else
            {
                $self->addtestresults( "\tegressContainsPids(): [".join(",", sort @pidsSeen)."] : PASSED" );
            }
        }
    }
    else
    {
        $self->addtestresults( "\tegressContainsPids(): FAILED! egress missing pid! Pids seen [".join(",", sort @pidsSeen)."], wanted [".join(",", @$pids)."]");
        $ret = $noFail ? 1 : 0;
    }
    return $ret;
}

sub checkEncodeFile
{
	my ( $self ) = @_;
    my $ret = 0;
    $self->addtestresults( "checkEncodeFile: started" );
    my $file = $self->{_resultspath}."/".$self->{_encodefile};
    my $csize = -s $file;
    if(defined $self->{_encodefilesize})
    {
        my $psize = $self->{_encodefilesize};
        my $rate = int( ($csize) / ( time-$self->{_encodestarted} ) );
        my $mbps = $rate * 8 / 10**6;
        $self->addtestresults( "\t: [$file] current size [$csize], previous size [$psize] encode rate [$rate Bps]" );
    }
    else
    {
        $self->{_encodestarted} = time;
    }
    $self->{_encodefilesize} = $csize;
    $self->addtestresults( "\t: [$file] current size $csize" );
	if ( $csize == 0 )
	{
		$self->addtestresults( "\t: FAILED! zero length encode file!" );
	} 
    else 
    {
		$self->addtestresults( "\t: PASSED" );
		$ret = 1;
	}
    
    $self->addtestresults( "checkEncodeFile: ended" );
	return $ret;
}

sub analyzeEncodeFile
{
	my ( $self, $pids ) = @_;
    my $ret = 1;
    $self->addtestresults( "analyzeEncodeFile: started");
    my $file = $self->{_resultspath}."/".$self->{_encodefile};
    my $csize = -s $file;
    my $sample = 500;
    $sample = $self->{_testparams}->{"f2fsample"} if($self->{_testparams}->{"f2fsample"});
    my $s = $sample*188;
    if($csize)
    {
        open(FH, "<$file");
        my $capture;
        read(FH, $capture, $s);
        my $start = 0; my $end = $sample;
        my $bytes = 0;
        my %h;
        while($capture)
        {
            my ($result, @pidsSeen) = &containsPids(\$capture, $pids, \%h);
            ++$bytes;
            if($result)
            {
                $self->addtestresults( "\t: [$file] [$start\-$end] contains pids [".join(",", sort @pidsSeen)."]" );
            }
            else
            {
                $self->addtestresults( "\t: FAILED! [$file] [$start\-$end] missing pid! Pids seen [".join(",", sort @pidsSeen)."]" );
                $ret = 0;
            }
            $start = $end;
            $end += $sample;
            read(FH, $capture, $s);
        }
        my $pidResult;
        foreach my $pid (keys %h)
        {
            $pidResult .= "\n\t: pid[$pid] total[".$h{$pid}."]";
        }
        $self->addtestresults( "\t: [$file] pid breakout".$pidResult);
		$self->addtestresults( "\t: PASSED" ) if($ret == 1);
    }
    else
    {
		$self->addtestresults( "\t: FAILED! zero length encode file!" );
        $ret = 0;
	} 
    $self->addtestresults( "analyzeEncodeFile: ended" );
	return $ret;
}

sub containsPids
{
    my ($capture, $pids, $h) = @_;
    my @bytes;
    eval
    {
        @bytes =  unpack "(C11 x177)*", $$capture; 
    };
    if($@)
    {
        return 0, "error analyzing capture";
    }

    my $pid;
    my $p0; my $p1; my $p2; my $p3; my $cc; my $af; my $sc;
    my $packet = 0;
    my $pid_packets = 0;
    my %pids_seen;
    my $total_pids = 0;
    my @seenpids;
    for(my $p=0; $p<scalar(@bytes); $p+=11, $packet += 188)
    {
        $p0= $bytes[$p];
        $p1 = $bytes[$p+1];
        $p2 = $bytes[$p+2];
        $p3 = $bytes[$p+3];
        $p1 = $p1 & 0x1f;
        $pid = $p2 | ($p1 << 8);
        $cc = $p3;
        $af = ($cc >> 4) & 0x03;
        $sc = ($cc >> 6) & 0x03;
        $cc = $cc & 0x0f;
        if(!$pids_seen{"$pid"})
        {
            $pids_seen{"$pid"} = 1;
            push @seenpids, $pid;
            ++$total_pids;
        }
        $h->{"$pid"} += 1;
    }
    my $result = 1;
    foreach my $p (@$pids)
    {
        if(! &isin($p, @seenpids))
        {
            $result = 0;
            last;
        }
    }

    return ($result, @seenpids);
}



sub isin
{
    my ($pid, @pids) = @_;
    foreach my $p (@pids)
    {
        return 1 if($p eq $pid);
    }
    return 0;
}

# void checkMemory()
# v3 function
# Checks the memory size of avcd and its child processes.
# If any process grows in memory size ten (10) consecutive times, the test fails
#
# Arguments: none
# Returns: 0|1
sub checkMemory
{
    my ($self) = @_;
    $self->addtestresults( "checkMemory(): Checking AVCD memory" );

    my $memorysampletime = $self->{_testparams}->{"memorysampletime"};
    $memorysampletime = 60 if(! $memorysampletime);
    $avcdtests::g_lasttime |= 0;

    my $currenttime = time;
    my $resettime = 0;
    # find avcd pids
    my $ppid = $avcd->{KIDS}[0]->{PID};
    my $ps = `ps -ef| grep avcd | grep $ppid | grep -v grep | grep logfile`;
    $ps =~ s/( +)/ /g;
    my @lines = split(/\x0a/, $ps); # each line contains a parent process or kid process
    my @pids;
    push @pids, $ppid; # main avcd pid
    foreach my $line (@lines)
    {
        my ($a, $pid, $cppid) = split(/ /, $line);
        next if($pid eq $ppid);
        if($cppid eq $ppid) # one of ours
        {
            push @pids, $pid;
        }
    }

    my $lxs = Sys::Statistics::Linux::Processes->new;
    $lxs->init;
    sleep 1;
    my $stat = $lxs->get;
    my $failed = 0;
    foreach my $ppid (@pids)
    {
        open(_INFO,"</proc/$ppid/stat") or warn( "Can't open /proc/$ppid/stat: $!\n");
        my @info = split(/\s+/,<_INFO>);
        close(_INFO);

        my %process;
        $process{process} = $info[1];
        $process{utime} = $info[13] / 100;
        $process{stime} = $info[14] / 100;
        $process{cutime} = $info[15] / 100;
        $process{cstime} = $info[16] / 100;
        $process{vsize}  = $info[22];
        $process{rss} = $info[23] * 4;

        $memorystats->{$ppid}->{"process name"} = $process{"process"};
        push @{$memorystats->{$ppid}->{"rss"}}, $process{rss};
        $memorystats->{$ppid}->{"starting rss"} = $process{rss} if(! defined $memorystats->{$ppid}->{"starting rss"});
        $memorystats->{$ppid}->{"current rss"} = $process{rss};

        push @{$memorystats->{$ppid}->{"vsize"}}, $process{vsize};
        $memorystats->{$ppid}->{"starting vsize"} = $process{vsize} if(! defined $memorystats->{$ppid}->{"starting vsize"});
        $memorystats->{$ppid}->{"current vsize"} = $process{vsize};
        $memorystats->{$ppid}->{"memory score"} = 0 if(! defined $memorystats->{$ppid}->{"memory score"});
        ++$memorystats->{$ppid}->{"numberofchecks"};

        my (@sizes) = split(/ / , $memorystats->{$ppid}->{"vsize"});
        my $mems;
        my $i = 0;
        my $lmem = -1;
        foreach my $mem (@{$memorystats->{$ppid}->{"rss"}})
        {
            my $size = @{$memorystats->{$ppid}->{"rss"}}[$i];
            if($mem != $lmem)
            {
                $mems .= $size."[$i] ";
            }
            $lmem = $mem;
            ++$i;
        }
        $mems = @{$memorystats->{$ppid}->{"rss"}}[$i-1]."[".($i-1)."] ".@{$memorystats->{$ppid}->{"rss"}}[$i-2]."[".($i-2)."] " if( $i > 1 );

        # every memory sample size, average the last X mem figures, if current average > last average, +1 else -1
        # every x minutes check for growth
        # get an average for the last minute, did this minute have an increase?
        # yes, score +1, no, score -1

        if( ($currenttime - $avcdtests::g_lasttime) > $memorysampletime )
        {
            my $sum = 0;
            my $total = scalar(@{$memorystats->{$ppid}->{"rss"}});
            foreach my $rssvalue (@{$memorystats->{$ppid}->{"rss"}})
            {
                $sum += $rssvalue;
            }
            @{$memorystats->{$ppid}->{"rss"}} = ();
            unshift @{$memorystats->{$ppid}->{"average rss"}}, sprintf("%d", $sum/$total);
            $self->addtestresults("\tPASS: ".$process{process}."rss averages [".join(", ", @{$memorystats->{$ppid}->{"average rss"}})."]" );

            if(scalar(@{$memorystats->{$ppid}->{"average rss"}}) > 1)
            {
                if(@{$memorystats->{$ppid}->{"average rss"}}[0] > @{$memorystats->{$ppid}->{"average rss"}}[1])
                {
                    ++$memorystats->{$ppid}->{"memory score"} if($memorystats->{$ppid}->{"memory score"} < 10);
                }
                else
                {
                    --$memorystats->{$ppid}->{"memory score"} if($memorystats->{$ppid}->{"memory score"} > -10);
                }
            }
            $self->addtestresults("\t".$process{process}."[$ppid] average rss for the last ".$memorysampletime. "s [".
                                  @{$memorystats->{$ppid}->{"average rss"}}[0]."]");
            $resettime = 1;

        }

        $mems .= "[";
        $mems .= "+" if($memorystats->{$ppid}->{"memory score"} >= 0);
        $mems .= $memorystats->{$ppid}->{"memory score"}."] ";
        $self->addtestresults("\t".$process{process}."[$ppid] memory stats [$mems]");
        my $svsize = $memorystats->{$ppid}->{"starting vsize"};
        my $srsize = $memorystats->{$ppid}->{"starting rss"};
        my $cvsize = $memorystats->{$ppid}->{"current vsize"};
        my $crsize = $memorystats->{$ppid}->{"current rss"};

        $self->addtestresults("\t".$process{process}."[$ppid] starting rsize [".$srsize."] current rsize [".$crsize."] diff [".($crsize - $srsize)."]");
        $self->addtestresults("\t".$process{process}."[$ppid] starting vsize [".$svsize."] current vsize [".$cvsize."] diff [".($cvsize - $svsize)."]");

        $self->{"unittests"}->{"monitormemory"}->{"$process{process} [$ppid] vsize s/c/d"} = "[".$svsize."] [".$cvsize."] [".($cvsize - $svsize)."]";

        if($memorystats->{$ppid}->{"memory score"} > 10)
        {
            ++$failed;
        }
        # log all memory stats once a minute or if $failed
        #if($memorystats->{$ppid}->{"numberofchecks"} % 6 == 0 || $failed)
        #{
        #    $self->addtestresults($process{process}."[$ppid] all rss stats [".$memorystats->{$ppid}->{"rss"}."]");
        #    $self->addtestresults($process{process}."[$ppid] all vsize stats [".$memorystats->{$ppid}->{"vsize"}."]");
        #welco}


    }
    ++$self->{"unittests"}->{"monitormemory"}->{"iterations"};
    if($resettime)
    {
        $memorystats->{$ppid}->{"last memory analysis"} = time;
        $currenttime = time;
        $avcdtests::g_lasttime = time;
        $resettime = 0;
    }
    # pass/fail?
    # if any process scored over 10, fail 
    if($failed)
    {
        $self->addtestresults( "checkMemory() FAILED: avcd process over-consumed memory!" );
		return( 0 );    
    }
	$self->addtestresults( "checkMemory(): PASSED" );
	return( 1 );
}


# void checkSourceFile()
#
# Checks the file size of the input media vile of the 
# current test defined by 'srcfile'.
# If file size is 0 or doesn't exist, clean up and exit
# If file size is greater than 0bytes return
#
# Arguments: none
# Returns: void
sub checkSourceFile
{
    my ($self) = @_;
    #$self->addtestresults( "Validating source file: '$self->{_srcfile}' " );
    
    if( $self->{_srcfile} eq "" )
    {
    	$self->addtestresults( "Validating source file: -> FAILED: No source file specified in test case." );
    	return(0);
    }
    
    my $srcString = cwd() . "/streams/$self->{_srcfile}";
	if (! -e $srcString )
	{
		$self->addtestresults( "Validating source file: -> FAILED: '$srcString' does NOT exist" );
		return( 0 );
	}
	
    if( -z $srcString )
    {
		$self->addtestresults( "Validating source file: -> FAILED: '$srcString' is zero length!" );
		return( 0 );
    }
        
	$self->addtestresults( "Validating source file: -> PASSED" );
	return( 1 );
}

sub checkConfig
{
	my ( $self ) = @_;
    my $failures = 0;
    $self->addtestresults("checkConfig(): checking avcd running config, sleeping for 5s");
    sleep 5;
    my $wanteddeinterlace = $self->{_wanteddeinterlace};
    my $wantedinterlace = $self->{_wantedinterlace};
    $self->addtestresults("checkConfig(): wantedinterlace $wantedinterlace");
    # open port to local C&C interface
    my $sock = new IO::Socket::INET (
        PeerAddr => "localhost",
        PeerPort =>  ($self->{_testparams}->{"--cc-port"}) ? $self->{_testparams}->{"--cc-port"} : 26000,
        Proto => 'tcp'
        );
    $sock->autoflush(1);
    print $sock "get:type=running_nodes\x0a";
    my $resp;
    my $bytes;
    do
    {
        $sock->recv($bytes, 1024);
        $resp .= $bytes;
    }while($bytes);
    my @lines = split(/\x0a/, $resp);
    my $founddeinterlace = undef;
    my $foundinterlace = undef;
    foreach my $line (@lines)
    {
        print $line."\n";
        if($line eq "WIRE=deinterlace,autoscale")
        {
            $founddeinterlace = $line;
        }
        if($line eq "WIRE=interlace,encoder")
        {
            $foundinterlace = $line;
        }
        # add other wants here
    }
    if($self->{_wanteddeinterlace})
    {
        if($founddeinterlace)
        {
            $self->addtestresults( "checkConfig(): PASSED wanted deinterlace filter, got [".$founddeinterlace."]" );
        }
        else 
        {
            $self->addtestresults( "checkConfig(): FAILED wanted deinterlace filter, got nothing." );
            ++$failures;
        }
    }
    elsif(! $self->{_wanteddeinterlace})
    {
        if($founddeinterlace)
        {
            $self->addtestresults( "checkConfig(): FAILED did NOT want deinterlace filter, got [".$founddeinterlace."]" );
            ++$failures;
        }
        else
        {
            $self->addtestresults( "checkConfig(): PASSED did not want deinterlace filter, got nothing." );
        }
    }

    if($self->{_wantedinterlace})
    {
        if($foundinterlace)
        {
            $self->addtestresults( "checkConfig(): PASSED wanted interlace filter, got [".$foundinterlace."]" );
        }
        else 
        {
            $self->addtestresults( "checkConfig(): FAILED wanted interlace filter, got nothing." );
            ++$failures;
        }
    }
    elsif(! $self->{_wantedinterlace})
    {
        if($foundinterlace)
        {
            $self->addtestresults( "checkConfig(): FAILED did NOT want interlace filter, got [".$foundinterlace."]" );
            ++$failures
        }
        else
        {
            $self->addtestresults( "checkConfig(): PASSED did not want interlace filter, got nothing." );
        }
    }
    return ($failures) ? 0 : 1;
}



# void create_configuration()
# v3
#
# Creates the needed command line arguments to the avcd binary by
# reading %avcdPresets in avcd.pm and comparing the build number
# with the preset specified in $self->{_configpreset}
sub createConfig
#
# returns (0|1)
{
    my ($self, $preset) = @_;
    my $continue = 0;

	# If the preset is not sent in as an argument to this sub
	# then use the one defined in the test object (which will be the normal case).
	$preset ||= $self->{_configpreset};
	
	# Get the AVCD versions allowed to use the specified preset, and get
	# the description of the preset.
	my $okVersions =  @{$avcd::avcdPresets{$preset}}[0];
	my $desc = @{$avcd::avcdPresets{$preset}}[1];
	
	# Log what's happening with the preset
    $self->addtestresults("createConfig(): using preset $preset - $desc ");

	# If the preset specified doesn't have an exact matching AVCD version
	# then see if there are any earlier builds listed in the preset,
	# if so log a warning and continue using the preset, if not log and fail.	
	if( 0 && $okVersions !~ /$main::fullVersion/ )
	{
		# Get the major and build version numbers
		my ( $version, $majorVersion, undef, $build ) = split( /\./, $main::fullVersion );
		$version =~ s/\D//g;
		
		# Compare the AVCD version numbers, if a lower build number is found for the same "version"
		# then continue.  In other words if 2.11.0.2500 is listed, and the testing build version 
		# of AVCD greater, such as 2.11.0.25100, but build 25100 is not listed, then continue the test
		foreach( reverse(split( /,/, $okVersions)) )
		{
			my ($okVersion, $okMajorVersion, $okBuild) = (split( /\./, $_))[0,1,3];
			#print "\nDBG: version=$version, majorVersion=$majorVersion, build=$build\n";
			#print "DBG: okVersion=$okVersion, okMajorVersion=$okMajorVersion, okBuild=$okBuild\n";
			if( ($majorVersion == $okMajorVersion) && ($version == $okVersion) )
			{
				if( int($build) == int($okBuild) )
				{
					$self->addtestresults( "createConfig(): -> PASSED" );
					$continue = 1;
				}
				elsif( int($build) > int($okBuild) )
				{
					$self->addtestresults( "createConfig(): -> WARNING - No exact match, this preset is available for ($okVersions), possibly usable for build $build, you better check, add $version.$majorVersion.$build to preset $preset if it's okay, continuing." );
					$self->{_testwarningscount}++;
					$continue = 1;
				}
			}
			last if( $continue );
		}
		
		# Bail out if the $continue variable is still set to 0
		if( !$continue )
		{  
			$self->addtestresults( "createConfig(): -> FAILED - Preset not available for this avcd version. Usable versions for this preset are ($okVersions)." );
			return(0);
		}
	}

    my $config;
    my $ccport = exists $self->{_testparams}->{"--cc-port"} ? $self->{_testparams}->{"--cc-port"} : 26000; 
    for(my $i=3;$i<scalar( @{$avcd::avcdPresets{$preset}} );$i+=1)
    {
        # open port to local C&C interface
        my $sock = new IO::Socket::INET (
            PeerAddr => "localhost",
            PeerPort => $ccport,
            Proto => 'tcp'
            );
        $sock->autoflush(1);
        # push each CMD to the C&C port, after massage
        my $cmd = @{$avcd::avcdPresets{$preset}}[$i];
        $cmd =~ s/SRCFILE/$self->{_srcfile}/g;
        $cmd =~ s/SRCADDR/src-addr=$self->{_testparams}->{"--src-addr"}/g;
        $cmd =~ s/SRCPORT/src-port=$self->{_testparams}->{"--src-port"}/g;
        $cmd =~ s/DSTADDR/dst-addr=$self->{_testparams}->{"--dst-addr"}/g;
        $cmd =~ s/DSTPORT/dst-port=$self->{_testparams}->{"--dst-port"}/g;
        $cmd =~ s/SOURCE/SOURCE=$self->{_testparams}->{"--src-addr"}:$self->{_testparams}->{"--src-port"}/g;
        $cmd =~ s/DEST/DEST=$self->{_testparams}->{"--dst-addr"}:$self->{_testparams}->{"--dst-port"}/g;
        $cmd =~ s/RESULTS/$self->{_resultspath}/g;
        $cmd =~ s/ENCODEFILE/$self->{_encodefile}/g;
        $cmd =~ s/\s/\x0a/g;
        $config .= $cmd."\n";
        $self->addtestresults( "createConfig(): running with $cmd: PASSED" );
        print $sock $cmd;#.'\x0a'.'\x0d';
        my $resp;
        $sock->recv($resp, 80);
        #print "\nKO $cmd\nresp: $resp";
        #sleep 1;
        #writeCmd(
    }
    $self->addtestresults( "createConfig(): created/pushed configuration: PASSED\n\n$config" );
    return(1); 	

    my $path = @{$avcd::avcdPresets{$preset}}[2];
    my $master = @{$avcd::avcdPresets{$preset}}[3];
    for(my $i=3;$i<scalar( @{$avcd::avcdPresets{$preset}} );$i+=1)
    {
        my $file = @{$avcd::avcdPresets{$preset}}[$i+0];
        my $conf = @{$avcd::avcdPresets{$preset}}[$i+1];
        $conf =~ s/PATH/$path/g;
        $conf =~ s/SRCFILE/$self->{_srcfile}/g;
        $conf =~ s/SRCADDR/$self->{_testparams}->{"--src-addr"}/g;
        $conf =~ s/DSTADDR/$self->{_testparams}->{"--dst-addr"}/g;
        $conf =~ s/RESULTS/$self->{_resultspath}/g;
        $conf =~ s/ENCODEFILE/$self->{_encodefile}/g;
        $conf =~ s/\s/\x0a/g;
        $conf .= "\n";
        `mkdir -p $path` if(! -e $path);
        open(FH, ">$path/$file");
        print FH $conf;
        close FH;

        $self->addtestresults( "createConfig():(): file: $file\n$conf\nPASSED" );
    }
    $self->addtestresults( "createConfig():: created conf files" );
    push( @avcdArgs, "-m");
    push( @avcdArgs, "$path/$master" );

    return(1); 	
}



# void gettestparams()
#
# Pulls in -- CLI input arguments to the script and avcd
# and stores them in the class member var _testparams
# These input arguments come in as ARGV[3] to the
# regression-test script, returns void
#
sub gettestparams
{
    my ($self) = @_;
    my $line = $ARGV[3];
    $line =~ s/--test-params=//;
    my @pairs = split(/,/, $line);
    foreach my $pair (@pairs)
    {
        my ($tag, $val) = split(/=/, $pair);
        $self->{_testparams}->{$tag} = $val;
    }
}

# LIST getavcdtestparams()
#
# Returns a list of avcd parameters pulled from the
# CLI input to the regression-test script
# 
sub getavcdtestparams
{
    my ($self, $version) = @_;
    my @avcdtestparams;
    my ($k, $v );
    $version ||= undef;
    
    while( ($k,$v) = each %{$self->{_testparams}})
    {
    	#print "k = $k\n";
        if($k =~ /--/) # avcd param
        {
            push( @avcdtestparams, $k );
            push( @avcdArgs, "$k=$v" );
        }
    };    
    
    if(0)# defined($version) and $version == 3 )
    {
		# Set some defaults
		if ( !grep(/--src-port/, @avcdArgs) )
		{
			push( @avcdArgs, "--src-port=5500" );
			$self->{_testparams}->{'--src-port'} = "5500";
		}
		if ( !grep(/--dst-port/, @avcdArgs) )
		{
			push( @avcdArgs, "--dst-port=5500" );
			$self->{_testparams}->{'--dst-port'} = "5500";
		}

    	return( @avcdArgs );

    } else {
    	return(@avcdtestparams);
    }
}

sub catchsignals
{
    $caughtsignal = 1;
}

sub provideRandomStream
{
	my( $self ) = @_;

    my $tsPlayPid = $tsPlay->{KIDS}[0]->{PID};
    if($tsPlayPid)
    {
        my $res = kill 0=>$tsPlayPid;
        if($res)
        {
            $self->addtestresults( "provideRandomStream():: stream still running" );
            return 1;
        }
    }
    $self->addtestresults( "provideRandomStream():: starting stream" );
    &startStream( $self, 1 );
}

sub startStream
{
	my( $self, $iterations ) = @_;
	my ( $in, $out, $err );
    my $srcFile;
    if( ref($self->{_srcfile}) eq "ARRAY")
    {
        $srcFile = $self->{_srcfile}[rand(scalar(@{$self->{_srcfile}}))];
    }
    else
    {
        $srcFile = $self->{_srcfile};
    }

    if(! $iterations)
    {
        $iterations = "-l";
    }
    else
    {
        $iterations = "";
    }
	$srcFile = cwd() . "/streams/$srcFile";
	my @tcpplayparams;
    @tcpplayparams = ("ts_play", $srcFile, $self->{_testparams}->{'--src-addr'}, $self->{_testparams}->{'--src-port'}, "99999") if($srcFile =~ /\.ts/);
    @tcpplayparams = ("tcpplay", $iterations, "-f", $srcFile, "-a", $self->{_testparams}->{'--src-addr'}, "-p", $self->{_testparams}->{'--src-port'}, ">/dev/null") if($srcFile =~ m/\.dump/ || $srcFile =~ m/\.pcap/);

	$self->addtestresults("Starting ".$tcpplayparams[0]." with params => ".join(' ', @tcpplayparams). " ");	
	
	# Make sure the source IP address is set
	if ( !defined($self->{_testparams}->{'--src-addr'}) )
	{
		&generic::stageappend( "FAILED: No source IP address specified");
		return(0);
		#zCleanUp($self);
	}
	
	# Make sure ts_play exists on the system, should be in the PATH
	if ( `ts_play` !~ /ts_play usage:/ )
	{
		&generic::stageappend( "FAILED: ts_play not found in the PATH");
		return(0);
	}
	
	$tsPlay = start( \@tcpplayparams, \$in, \$out, \$err );    
	$self->addtestresults("Sleep for 1 seconds and make sure ".$tcpplayparams[0]." process is running.");
	sleep(1);
	
	$tsPlay->reap_nb(); 
	#$tsPlayPid = $t1->{KIDS}[0]->{PID};
	
	return(1);
}

sub stopStream
{
	my( $self ) = @_;
	$self->addtestresults( "Stopping source stream playback ");
	if ( defined($avcd) )
	{
		$tsPlay->kill_kill(); 
		&generic::stageappend("source stream playback has been stopped");
	} else {
		&generic::stageappend( "source stream playback not running, nothing to do" );
	}
	return(1);
}

sub startAvcd
{
	my ( $self ) = @_;
	my ( $in, $out, $err );
	
	#print"\nstartAvcd(): \@avcdArgs = @avcdArgs\n";
	unshift( @avcdArgs, $self->{_testbinpath} );
    my $ccport = exists $self->{_testparams}->{"--cc-port"} ? $self->{_testparams}->{"--cc-port"} : 26000; 
    $self->{"ccport"} = $ccport; # save this for other use

    push @avcdArgs, ("--cc-port", $self->{'ccport'}, "-l", "/var/log/avcd.test-".$self->{_testid}.".".$ARGV[0].".log");
	$self->addtestresults("Starting AVCD with params => ".join(' ', @avcdArgs) );

	# Make sure the source and estination IP addresses are set
	if (0)# !defined($self->{_testparams}->{'--src-addr'}) or !defined($self->{_testparams}->{'--dst-addr'}) )
	{
		$self->addtestresults( "startAVCD() - FAILED: Missing '--src-addr' or '--dst-addr'");
		return(0);
	}
	$avcd = start( \@avcdArgs, \$in, \$out, \$err );
	$self->addtestresults("Sleep for 1 seconds and make sure AVCD process is running.");
	sleep(1);
	eval{ $avcd->result(0) };
	#print( "\nDBG \$@ = $@\n");
	#print( "\nDBG \$? = " . $? . "\n" );
	#print( "\nDBG: in=$in, out=$out, err=$err\n");
	$avcd->reap_nb(); 
	return(1);
}

sub stopAvcd
{
	my ( $self, $pid ) = @_;
	$self->addtestresults("stopAvcd: started");
	if ( defined($avcd) )
	{	
        $avcd->kill_kill( grace=>1);
        sleep( 2 );
		$self->addtestresults("\t: avcd has been stopped");
	} 
    else 
    {
        $self->addtestresults( "avcd not running, nothing to do" );
	}
    $self->addtestresults("stopAvcd: ended");
	return(1);
}

sub isAvcdRunning
{
	my( $self ) = @_;
    my $ret = 0;
	# grep the proc list for avcd
    my $ps = "ps -eaf | grep ".$self->{_testbinpath}." | grep -v grep";
	my $avcdPids = `$ps`;
	if ( $avcdPids eq "" )
	{
		$self->addtestresults("isAvcdRunning(): FAILED! AVCD is NOT running");
        $ret = -1 if($self->{_filetofilemode});
	}
    else
    {
        $ret = 1;
    }
	if($ret)
    {
        $self->addtestresults( "isAvcdRunning(): PASSED" );
    }
    else
    {
        $self->addtestresults( "isAvcdRunning(): FAILED" );
    }
	return( $ret );
}

sub isAvcdNotRunning
{
	my( $self ) = @_;
    my $ret = 0;
	# grep the proc list for avcd
    my $ps = "ps -eaf | grep ".$self->{_testbinpath}." | grep -v grep";
	my $avcdPids = `$ps`;
	if ( $avcdPids eq "" )
	{
        $ret = 1;
        $ret = -1 if($self->{_filetofilemode});
	}
    else
    {
        $ret = 0;
    }

	if($ret)
    {
        $self->addtestresults( "isAvcdNotRunning(): PASSED" );
    }
    else
    {
        $self->addtestresults( "isAvcdNotRunning(): avcd is already running! FAILED" );
    }
	return( $ret );
}


sub zCleanUp
{
	my ( $self ) = @_;
	stopAvcd($self);
	stopStream($self);
	#$self->endtest();
    print "\n";	# Add one more newline to STDOUT, to push the command prompt down a bit
    #print( "DBG: _testmode = $self->{_testmode}\n");
    return 0;
	if( defined($self->{_testmode}) )
	{
		if( $self->{_testmode} eq 'batch')
		{
			return(0);
		} 
		
		else 
		{
			exit(0);
		}
	} 

}

# void pause( INT $seconds )
#
# Sleeps the program for $seconds seconds, this doesn't sleep
# any running forked processes.
sub pause
{
    use Term::ReadKey;
	my( $self, $seconds ) = @_;
	$self->addtestresults( "Pausing main program for $seconds seconds (hit 'p' to pass, 'f' to fail test)" );

    my $t1 = [gettimeofday];
    my $elapsed;
    do
    {
        ReadMode 4; # Turn off controls keys
        my $key = ReadKey(-1);
        if($key)
        {
            if($key eq "f")
            {
                $self->addtestresults( "pause(): user has failed test manually: FAILED" );
                ReadMode 0; # Reset tty mode before exiting
                return 0;
            }
            if($key eq "p")
            {
                $self->addtestresults( "pause(): user has stopped test manually: PASSED" );
                ReadMode 0; # Reset tty mode before exiting
                return -1;
            }
            exit if($key eq "q");
        }
        $elapsed = tv_interval($t1, [gettimeofday]);
        nanosleep(100);
    }while($elapsed < $seconds);
    ReadMode 0; # Reset tty mode before exiting
	return(1);
}

sub exposePmt
{
    my ($self) = @_;
    my %assetInfo;
    my $varInfo;
    
    &parsePackets($self->{_capture}, \%assetInfo);
    
    $varInfo .= "[pmt:".$assetInfo{pmt}->{PID}."] ";
    $varInfo .= "[video:".$assetInfo{video}->{PID}."] ";
    $varInfo .= $assetInfo{video}->{streamtype}." ";
    $varInfo .= "(".$assetInfo{video}->{codec}.") ";
    if ($assetInfo{scte}->{codec})
    {
        
        $varInfo .= "[scte:".$assetInfo{scte}->{PID}."] ";
        $varInfo .= $assetInfo{scte}->{streamtype}." ";
        $varInfo .= "(".$assetInfo{scte}->{codec}.") ";
    }
    foreach my $key (keys %{$assetInfo{audio}})
    {
        $varInfo .= "[audio:".$assetInfo{audio}->{$key}->{PID}."] ";
        $varInfo .= $assetInfo{audio}->{$key}->{streamtype}."-";
        if ($assetInfo{audio}->{$key}->{language})
        {
            $varInfo .= $assetInfo{audio}->{$key}->{language}." ";
        }
        $varInfo .= "(".$assetInfo{audio}->{$key}->{codec}.") ";
    }
    $self->addtestresults( "exposePmt() PASSED: $varInfo" );
    return(1);
}

sub parsePackets
{
    my ($capture, $assetInfo) = @_;
    
    my $pmtpid = 0;
    my $bp  = 1;    # A pointer, to where we are in the bit stream
    my $pp  = 1;    # A pointer, to what bit we're on in a TS packet (1-188)    
    my $tsHeader;   # The TS header binary bits
    my $payload;    # The TS payload, binary bits
    my $sb;         # Sync byte, 8 bits, should be: 71 = 0x47 = b01000111
    my $te;         # Transport Error, 1 bit: 1=error, 0=ok
    my $ps;         # Payload Unit Start, 1 bit: 1= start of PES or PSI, 0=ignore
    my $tp ;        # Transport Priority, 1 bit: 1= this packet is high priority 
    my $pid;        # Packet ID, 13 bits
    my $sc;         # Scramble Control, 2 bits: 00=Not, 01=Reserved, 10=Even Key, 11=Odd Key
    my $af;         # Adaption Field, 2 bits: 01=Payload only, 10=AF Only, 11=AF and payload
    my $cc;         # Continuity Counter, 4 bits
    my $ao = 0;     # An AF offset used to jump over AF data, and get to the payload
    my $ii = 1;
    my $audio = "";
     
    foreach my $bit (split(//, $capture)) # BRENTON This is bytes not bits
    {
        # Gather up the TS header, bytes 1-4
        if( $pp >= 1 && $pp <= 4 )
        {
            $tsHeader .= $bit;
        }
        # Gather up the payload, bytes 5-188
        if ( $pp >= 5 && $pp <=188 )
        {
            $payload .= $bit;
        } 
        # If reached the end of a full 188 byte packet, need to process the TS header, 
        # and if needed the payload
        if ( $pp == 188 )
        {
            # Create a binary "string", a string of ones and zeros
            $tsHeader = unpack( "B*", $tsHeader );
            $payload  = unpack( "B*", $payload );
            
            # Populate the TS header variables
            $sb  = substr( $tsHeader, 0, 8);    # Sync byte
            $te  = substr( $tsHeader, 8, 1);    # Transport error bit
            $ps  = substr( $tsHeader, 9, 1);    # Payload unit start indicator
            $tp  = substr( $tsHeader, 10, 1);   # Transport priority
            $pid = substr( $tsHeader, 11, 13);  # Packet ID
            $sc  = substr( $tsHeader, 24, 2);   # Scrable control
            $af  = substr( $tsHeader, 26, 2);   # Adaptaion field
            $cc  = substr( $tsHeader, 28, 4);   # Continuity Counter
            
            # Convert to readable decimal values; binary to decimal conversion
            $sb  = bin2hex($sb);
            $pid = bin2dec($pid);
            $cc  = bin2dec($cc);

            
            # Add all pids found to the global %pids table, and default some fields if not
            # already set
            #$pids{$pid}->{exits}        = 1;
            #$pids{$pid}->{ccErrors}     = 0 if ( !defined($pids{$pid}->{ccErrors}));
            #$pids{$pid}->{nextCC}       = $cc if ( !defined($pids{$pid}->{nextCC}) );
            #$pids{$pid}->{ccErrors}++   if ( $pids{$pid}->{nextCC} != $cc );
            #$pids{$pid}->{nextCC}       = ($cc == 15) ? 0 :$cc+1 ;

            # Print out the TS header fields, if this packet is not a NULL packet
            # and if debug is set to 3 or greater
            
            #if( $pid != 8191 )
            #{
            #   #print "----------------------------------------------------------------------------------\n";
            #   #print "$type TS Header: sb=0x$sb, te=b$te, ps=b$ps, tp=b$tp, pid=$pid, sc=b$sc, af=b$af, cc=$cc\n";
            #             
            #}

            # Process the adaptation field, if the af value is 2 or 3
            if ( $af eq "10" || $af eq "11" )
            {
                my $fl;     # Field Length, 8 bits
                my $di;     # Discontinuity indicator, 1 bit
                my $ra;     # Random access indicator, 1 bit
                my $es;     # Elementary stream priority, 1 bit
                my $pcr;    # Program clock reference, 1 bit
                
                $fl = substr( $payload, 0, 8);
                $fl = bin2dec( $fl );
                #print "AF Header: fl=$fl\n";
                
                # Get additional AF data if not NULL stuffing   
                if ( $fl > 0 )
                {
                    $ao     = ( $fl*8 )+8;                  # The AF offset into the payload, in bits
                    $di     = substr( $payload, 8, 1 );
                    $ra     = substr( $payload, 9, 1 );
                    $es     = substr( $payload, 10, 1);
                    $pcr    = substr( $payload, 11, 1); 
                    #print "di=b$di, ra=b$ra, es=b$es, pcr=b$pcr\n";        
                }
            }
        
            # Check for PSI tables by checking the payload_unit_start bit from the tsHeader
            if ( $ps == 1 )
            {
                # All PSI tables have these fields in common                
                my $pf  = substr( $payload, $ao,    8 );    # Pointer field, 8 bits
                my $ti  = substr( $payload, $ao+8,  8 );    # Table ID, 8 bits, should be 0 = 0x00 = b00000000 for PAT
                my $si  = substr( $payload, $ao+16, 1 );    # Section syntax indicator, 1 bit, always 1 for PAT
                my $x0  = substr( $payload, $ao+17, 1 );    # ??, 1 bit,  Aways 0 for PAT
                my $r1  = substr( $payload, $ao+18, 2 );    # Reserved, 2 bits, always 3 = 0x03 = b11
                my $sl  = substr( $payload, $ao+20, 12);    # Section length, 12 bits, first two bits must be 0
                my $ts  = substr( $payload, $ao+32, 16);    # Transport Stream ID/Program number, 16 bits
                my $r2  = substr( $payload, $ao+48, 2 );    # Reserved, 2 bits
                my $vn  = substr( $payload, $ao+50, 5 );    # Version Number, 5 bits
                my $ni  = substr( $payload, $ao+55, 1 );    # Current Next Indicator, 1 bit
                my $sn  = substr( $payload, $ao+56, 8 );    # Section Number, 8 bits
                my $ls  = substr( $payload, $ao+64, 8 );    # Last Section Number, 8 bits
                my $cr;                                     # CRC 32, 32 bits       

                # Additional PAT data       
                my $pn;                                     # Program Number, 16 bits
                my $r3;                                     # Reserved, 3 bits
                # Make this global so we can open PMT
                my $pi;                                        # Network or Program PID, 13 bits
                
                # Additional PMT data
                my $r4;                                     # Reserved, 3 bits
                my $pp;                                     # PCR pid, 13 bits
                my $r5;                                     # Reserved, 4 bits
                my $pl;                                     # Program Length, 12 bits;
                my $st;                                     # Stream Type, 8 bits
                my $r6;                                     # Reserved, 3 bits
                my $ep;                                     # Elementary PID, 13 bits;
                my $r7;                                     # Reserved, 4 bits
                my $el;                                     # ES Info Length, 12 bits;
                
                # Descriptor variables
                my $dt;                                     # The ES data tag, 8 bits
                my $dl;                                     # The ES description length in bytes, 8 bits
                my $lc;                                     # Language code, 24 bits (3byte sections)
                my $at;                                     # Audio type, 8 bits
                                    
                # Convert common PSI vars to human readable
                $pf = bin2dec( $pf );
                $ti = bin2hex( $ti );
                $sl = bin2dec( $sl );
                $ts = bin2dec( $ts );
                $vn = bin2dec( $vn );
                $sn = bin2dec( $sn );
                $ls = bin2dec( $ls );
                
                #my $pmtType = ($psiTables{$ti} ? $psiTables{$ti} : "UNDF" );
                
                # To figure out how many bits left in this section to read
                # Use the section length, and subtract the PMT header bits (40) already
                # read in just after the section length to last section number
                my $bitsLeftToRead = ($sl*8) - 40;
                
                #print "PSI Header: $pmtType - ao=$ao, pf=$pf, ti=0x$ti, si=b$si, x0=b$x0, r1=b$r1, ";
                #print "PSI Header: $pmtType - sl=$sl, ts=$ts, r2=b$r2, vn=$vn, ni=b$ni, sn=$sn, ls=$ls";
                #print "bitsLeft=$bitsLeftToRead";
 
                # PAT data rides on PID 0, get PAT specific data.
                if ( $pid == 0 && $ti eq "00")
                {
                    #BRENTON
                    # PAT data
                    # http://www.etherguidesystems.com/help/sdos/mpeg/syntax/tablesections/pat.aspx
                    
                    #PMT data
                    # http://en.wikipedia.org/wiki/Program-specific_information#PMT_.28program_map_table.29
                    
                    # This is 'broken' and will only get the first program listed in the PAT
                    for ( my $i=0; $i < 4; $i++ )
                    {   
                        #$pn = bin2dec( substr( $payload, $ao+72, 16 ) );
                        #$r3 = substr( $payload, $ao+88, 3  );
                        $pi = bin2dec( substr( $payload, $ao+91, 13 ) );
                        $pmtpid = $pi;
                    }
                    $cr = bin2hex( substr( $payload, $ao+104, 32) );                
                    # update the pat hash with the pid to program number xref
                    #$pat{$pi}->{programNumber} = $pn;
                    #dPrint( "PAT: pn=$pn, r3=b$r3, pi=$pi, cr=0x$cr", 3 );
                }
                else {

                    # PAT
                    #if ( $ti eq "00" )
                    #{
                    #    #dPrint( "PAT:");
                    #}
                    #
                    ## CAT
                    #if( $ti eq "01" )
                    #{
                    #    #dPrint( "CAT: ");
                    #}
                    
                    # PMT data fields
                    #print "$pid = $pmtpip\n";
                    if ( $pid eq $pmtpid)
                    {
                        
                        my %stKeys;
                        my $key;
                        my $lc1;
                        my $lc2;
                        my $lc3;
                        my $codec;
                        my $pAudioFlag = 0;
                        my $pVideoFlag = 0;
                        my $audioToken = 0;
                        
                        
                        #Add PMT to the return hash
                        $assetInfo->{pmt}->{"PID"} = "$pmtpid";
                        
                        $r4 = substr( $payload, $ao+72, 3 );            # Reserved
                        $pp = bin2dec( substr( $payload, $ao+75, 13) ); # PCR PID
                        $r5 = substr( $payload, $ao+88, 4 );            # Reserved
                        $pl = bin2dec( substr( $payload, $ao+92, 12) ); # Program info length, 0 = no descriptors
                        #print "PMT: r4=b$r4, pp=$pp, r5=b$r5, pl=$pl\n";
                        $bitsLeftToRead -= 32;
                        
                        # If there are program descriptors, then another offset is needed to get
                        # past them, and into the PMT data.
                        # If the program_length is 0 then there are no program descriptors
                        my $d1 = $ao+104+($pl*8);   # PMT data offset
                
                        # Pull program descriptors here, see spec.
                        # To Do - Save program descriptors 
                        my $i = 0;
                        my ( $pdt, $pdl, $fi ) = ( '', '', '');
                        
                        #print "\tProgram info length: $pl\n";
                        
                        while ( $i < ($pl*8) )
                        {
                            $pdt = bin2hex(substr($payload, $ao+104+$i,8));   # Descriptor tag
                            $pdl = bin2dec(substr($payload, $ao+112+$i,8));   # Descriptor length
                            
                            #print "Descriptor tag: 0x$pdt\n";
                            #print "Descriptor length: $pdl\n";
                            $i += 16;
                            
                            # If the tag=5 its a registration descriptor, and needs to be  
                            # checked for SCTE-35 (ad insertion)
                            
                            $i += $pdl*8;
                            
                            #print "program descriptor: pdt=$pdt, pdl=$pdl, fi=0x$fi\n";
                        }
                        $bitsLeftToRead -= ($pl*8);
                        #print "\n\n\n";
                        
                        #if( 0 ){
                        #print( " ------------------------------------\n" );
                        #print( "PSI Header: $pmtType - ao=$ao, pf=$pf, ti=0x$ti, si=b$si, x0=b$x0, r1=b$r1,\n" );
                        #print( "PSI Header: $pmtType - sl=$sl, ts=$ts, r2=b$r2, vn=$vn, ni=b$ni, sn=$sn, ls=$ls\n" );
                        #print( "PMT: r4=b$r4, pp=$pp, r5=b$r5, pl=$pl\n" );
                        #print( " program descriptor: pdt=$pdt, pdl=$pdl, fi=0x$fi\n");
                        #}

                        # Loop untill there are only 32 bits left, these are the
                        # CRC bits, the last 32 bits of the packet
                        while ( $bitsLeftToRead != 32 )
                        {
                            #dPrint( "bitsLeft = $bitsLeftToRead", 3 );
                            $st = bin2hex( substr($payload, $d1, 8) );      # Stream type
                            $r6 = substr( $payload, $d1+8, 3);              # Reserved
                            $ep = bin2dec( substr($payload, $d1+11, 13));   # Elementary PID
                            $r7 = substr( $payload, $d1+24, 4 );            # Reserved
                            $el = bin2dec( substr($payload, $d1+28, 12));   # ES info length, 0 = no descriptors
                            $bitsLeftToRead -= 40;

                            #print "  PMT: $streamType{$st}: st=0x$st, r6=b$r6, ep=$ep, r7=b$r7, el=$el\n";
                            
                            # Pull ES descriptors here, see spec.
                            my $i = $el*8;
                            while ( $i > 0 )
                            {
                                $dt = bin2dec( substr( $payload, $d1+40, 8) );  # The ES data tag, 8 bits
                                $dl = bin2dec( substr( $payload, $d1+48, 8) );  # The ES description length in bytes, 8 bits
                                
                                #print "ES Descriptor tag: 0x$dt\n";
                                #print "ES Descriptor length: $dl\n";
                                
                                my $dlm          = $dl*8;
                                $bitsLeftToRead -= 16;  
                                $i              -= 16;

                                #print "dt=$dt, dl=$dl, \n";
                                #print( " ES: dt=$dt, dl=$dl, dlm=$dlm\n" ) ;
                                
                                # so given a capture bytestream, I should be able to call your function and get elementary stream info i.e. pids, what stream descriptor, language
                                
                                # New function for anylazing hash
                                #exposePmt(): [video] 0x1b audio[0x81-eng] audio[0x81-spa]
                                #is what I'm thinkin
                                #exposePmt(): [pmt:1000] [video:2000] 0x1b [audio:3000]0x81-eng [audio:3001]:0x81-spa
                                                            
                                # ISO 639 Language Descriptor
                                if( $dt == 10 || $dt == 129 )
                                {
                                    $audioToken = 1;
                                    $lc = substr( $payload, $d1+56, 24 );   # The language descriptor, 24 bits
                                    $at = substr( $payload, $d1+80, 8 );    # The audio type, 8 bits
                                    $lc1 = bin2ascii( substr( $lc, 0, 8 ) );
                                    $lc2 = bin2ascii( substr( $lc, 8, 8 ) );
                                    $lc3 = bin2ascii( substr( $lc, 16, 8) );
                                    #print "lc=$lc1$lc2$lc3\n";

                                # ATSC program_identifier descriptor (SCTE 35)
                                } elsif ( $dt == 133 ) {
                                    
                                } else {

                                } 
                                $bitsLeftToRead -= $dlm;
                                $i  -= $dlm;
                                $d1 += ($dlm+16);
                                $el  = 0;                               
                            }                       
                            $d1 += 40;
                            
                            
                            
                            $stKeys{"0x01"} = "Video MPEG-1";
                            $stKeys{"0x02"} = "Video MPEG-2";
                            $stKeys{"0x03"} = "Audio MPEG-1";
                            $stKeys{"0x04"} = "Audio MPEG-2";
                            $stKeys{"0x05"}= "MPEG-2 private table sections";
                            $stKeys{"0x06"} = "MPEG-2 Packetized Elementary Stream";
                            $stKeys{"0x07"} = "MHEG Packets";
                            $stKeys{"0x08"} = "MPEG-2 Annex A DSM CC";
                            $stKeys{"0x09"} = "ITU-T Rec. H.222.1";
                            $stKeys{"0x0A"} = "ISO/IEC 13818-6 type A";
                            $stKeys{"0x0B"} = "ISO/IEC 13818-6 type B";
                            $stKeys{"0x0C"} = "ISO/IEC 13818-6 type C";
                            $stKeys{"0x0D"} = "ISO/IEC 13818-6 type D";
                            $stKeys{"0x0E"} = "ISO/IEC 13818-1 (MPEG-2) auxiliary";
                            $stKeys{"0x0F"} = "ISO/IEC 13818-7 Audio with ADTS";
                            $stKeys{"0x10"} = "ISO/IEC 14496-2 (MPEG-4) Visual";
                            $stKeys{"0x11"} = "ISO/IEC 14496-3 Audio with the LATM";
                            $stKeys{"0x12"} = "SL-packetized stream or FlexMux stream";
                            $stKeys{"0x13"} = "ISO/IEC 14496-1 SL-packetized stream or FlexMux";
                            $stKeys{"0x14"} = "ISO/IEC 13818-6 Synchronized Download Protocol";
                            $stKeys{"0x15"} = "Metadata carried in PES packets";
                            $stKeys{"0x16"} = "Metadata carried in metadata_sections";
                            $stKeys{"0x81"} = "AC3";
                            $stKeys{"0x86"} = "SCTE-35";
                            $stKeys{"0x87"} = "AC-3";
                            $stKeys{"0x1B"} = "Video MPEG-4";
                            #print "\n\nPID: $ep  TAG: 0x$st\n\n";
                            
                            #Lang information
                            if ($audioToken == 1)
                            {
                                if ( $audio !~ "$lc1$lc2$lc3")
                                {
                                    if($lc1 && $lc1 ne " ")
                                    {
                                        $assetInfo->{"audio"}->{$ii}->{"language"} = $lc1.$lc2.$lc3;
                                    }
                                    $assetInfo->{"audio"}->{$ii}->{"streamtype"} = "0x$st";
                                    $assetInfo->{"audio"}->{$ii}->{"PID"} = $ep;
                                    $audio .= "$lc1$lc2$lc3";
                                    
                                    foreach $key (%stKeys)
                                    {
                                        if ($key eq "0x$st")
                                        {
                                            $assetInfo->{"audio"}->{$ii}->{"codec"} = $stKeys{$key};
                                        }
                                    }
                                }
                                ++$ii;
                            }
                            if ($st eq "86")
                            {
                                   $assetInfo->{"scte"}->{"PID"} = $ep;
                                   $assetInfo->{"scte"}->{"streamtype"} = "0x$st";
                                   
                                   foreach $key (%stKeys)
                                    {
                                        if ($key eq "0x$st")
                                        {
                                            $assetInfo->{"scte"}->{"codec"} = $stKeys{$key};
                                        }
                                    }
                                   
                            }
                            else
                            {
                                $assetInfo->{"video"}->{"PID"} = $ep;
                                $assetInfo->{"video"}->{"streamtype"} = "0x".$st;
                                
                                foreach $key (%stKeys)
                                {
                                    if ($key eq "0x$st")
                                    {
                                        $assetInfo->{"video"}->{"codec"} = $stKeys{$key};
                                    }
                                }
                            }
                            
                            
                        }
                        #$cr = bin2hex( substr( $payload, $d1, 32) );
                        $cr = substr( $payload, $d1, 32);
                    }
                }       
            }         
            # reset loop variables for the next itteration
            $tsHeader   = undef;
            $payload    = undef;
            $pp         = 0;
            $ao         = 0;
        }
        
        # Increment the bit stream pointer, and the packet bit pointer
        $bp++;
        $pp++;
    }
    #print Dumper(\$assetInfo);
}


sub bin2hex
{
    my ( $b ) = @_;
    return( sprintf( '%02X', oct("0b$b")) );
}

sub bin2dec
{
    my( $b ) = @_;
    return unpack( "N", pack("B32", substr('0' x 32 . $b, -32)) );
}

sub bin2ascii
{
    my ( $b ) = @_;
    return( chr(bin2dec($b)) );
}

sub checkMdiDf
{
    my ($self, $runtime) = @_;
    my $targetbitrate = 0;
    my $start = [gettimeofday];
    my $dfstart = [gettimeofday];
    my @bytes;
    my $maxdiff = -1;
    my $mindiff = -1;
    my $maxdf = -1;
    my $mindf = -1;
    my $bitsthissample = 0;
    my $packetnumber = 0;
    my $sel;
    my $msg;
    my $t1;
    my $lastread = [gettimeofday];;
    my $elapsed = 0;
    my $df;
    my $dfelapsed;
    my $timeinterval;
    my $dftotals;
    my $dfiterations;
    my $averagedf;
    my $which;
    my $ii = 1;
    my $iterations = 0;
    my $bitrateAvg = 0;
    my $runTimeCounter = 0;
    $runtime = $runtime/.1;
    $timeinterval = 0.1;

    $which = $self->{_testparams}->{"--dst-addr"} if(! $which );
	my ( $success, $d ) = &setupcapture( $self, 
                                         $which,
                                         $self->{_testparams}->{"--dst-port"} );
    if($success)
    {
        my $sel = new IO::Select();
        $sel->add($d);
        
        while ($runTimeCounter < $runtime)
        {
            #print "Elapsed: $elapsed  Runtime: $runtime\n";
            my $t0 = [gettimeofday];
            my @ready = $sel->can_read(1);
            
            if(scalar(@ready))
            {
                $d->recv($msg, 1316);
                $bitsthissample += 1316*8;
                $t1 = [gettimeofday];
                my $diff;
                
                if($lastread)
                {
                    $elapsed = tv_interval($lastread, $t1);
                    my $shouldhaveread = ($targetbitrate*$elapsed);
                    $diff = (1316*8 - $shouldhaveread);
                    $maxdiff = $diff if( ($diff > $maxdiff && $diff) || $maxdiff == -1);
                    $mindiff= $diff if( ($diff < $mindiff && $diff) || $mindiff == -1);
                }
                $lastread = $t1;
                $elapsed = tv_interval($start, $t1);
                $dfelapsed = tv_interval($dfstart, $t1);
                
                if($elapsed > $timeinterval)
                {
                    if($dfelapsed > 0.1)
                    {
                        ++$iterations;
                        $targetbitrate = $bitsthissample/$elapsed;
                        $bitrateAvg += $targetbitrate;
                        $targetbitrate = $bitrateAvg/$iterations;
                        $targetbitrate = sprintf("%.0f", $targetbitrate);
                        $bitsthissample = 0;
                        $df = sprintf("%.6f", (1000* ($maxdiff - $mindiff) / ($targetbitrate)));
                        $maxdf = $df if(($df > $maxdf) || $maxdf == -1);
                        $mindf = $df if(($df < $mindf) || $mindf == -1 || $mindf == 0);
                        $dftotals += $df;
                        ++$dfiterations;
                        $averagedf = sprintf("%.6f", ($dftotals / $dfiterations));
                        $maxdiff = -1;
                        $mindiff = -1;
                        $dfstart = [gettimeofday];
                        ++$runTimeCounter; 
                    }
                    $start = [gettimeofday];
                    if ($maxdf > 50 )
                    {
                        $self->addtestresults( "checkMdiDf() FAILED: exceeded 50ms MIN[$mindf] AVG[$averagedf] MAX[$maxdf]" );
                        return(0);
                    } 
                }
            }
        }
        $self->addtestresults( "checkMdiDf() PASSED: MIN[$mindf] AVG[$averagedf] MAX[$maxdf]" );
        return(1);
    }
    else
    {
        $self->addtestresults( "checkMdiDf() FAILED: could not open socket" );
        return(0);
    }
}


sub checkMdiDfOld
{
    my ($self, $runtime) = @_;

    my $targetbitrate = 0;
    my $start = [gettimeofday];
    my $dfstart = [gettimeofday];
    my @bytes;
    my $maxdiff = -1;
    my $mindiff = -1;
    my $maxdf = -1;
    my $mindf = -1;
    my $bitsthissample = 0;
    my $packetnumber = 0;
    my $sel;
    my $msg;
    my $t1;
    my $lastread = [gettimeofday];;
    my $elapsed;
    my $df;
    my $dfelapsed;
    my $timeinterval;
    my $dftotals;
    my $dfiterations;
    my $averagedf;
    my $which;
    my $ii = 1;
    $timeinterval = 0.1;

    $which = $self->{_testparams}->{"--dst-addr"} if(! $which );
    print "\nRuntime $runtime";
	# Setup the socket, get it ready for real time capture
	my ( $success, $d ) = &setupcapture( $self, 
                                         $which,
                                         $self->{_testparams}->{"--dst-port"} );
    if($success)
    {
        my $sel = new IO::Select();
        $sel->add($d);
        do
        {
            my @ready = $sel->can_read(1);
            if(scalar(@ready))
            {
                $d->recv($msg, 1316);
                $bitsthissample += 1316*8;
                $t1 = [gettimeofday];
                # calc DF min/max
                my $diff;
                $elapsed = tv_interval($lastread, $t1);

                if($elapsed > $timeinterval)
                {
                    $lastread = $t1;
                    $targetbitrate = 5400000;#$bitsthissample/$elapsed;
                    print "\nbitsthissample $bitsthissample $elapsed targetbitrate $targetbitrate";

                    my $shouldhaveread = ($targetbitrate*$elapsed);
                    $diff = ($bitsthissample - $shouldhaveread);
                    $bitsthissample = 0;
                    print "\nshouldhaveread $shouldhaveread diff = $diff";
                    $maxdiff = $diff if( ($diff > $maxdiff && $diff) || $maxdiff == -1);
                    $mindiff= $diff if( ($diff < $mindiff && $diff) || $mindiff == -1);


                    $df = sprintf("%f", (1000* ($maxdiff - $mindiff) / ($targetbitrate)));
                    print "df=$df ";
                    $maxdf = $df if(($df > $maxdf) || $maxdf == -1);
                    $mindf = $df if(($df < $mindf) || $mindf == -1 || $mindf == 0);
                    $dftotals += $df;
                    ++$dfiterations;
                    $averagedf = sprintf("%.6f", ($dftotals / $dfiterations));
                    $maxdiff = -1;
                    $mindiff = -1;
                    if ($maxdf > 50 )
                    {
                        $self->addtestresults( "checkMdiDf() FAILED: exceeded 50ms MIN[$mindf] AVG[$averagedf] MAX[$maxdf]" );
                        return(0);
                    } 
                }
            }
            $elapsed = tv_interval($start, [gettimeofday]);
        }while ($elapsed < $runtime);
        $self->addtestresults( "checkMdiDf() PASSED: MIN[$mindf] AVG[$averagedf] MAX[$maxdf]" );
        return(1);
    }
    else
    {
        $self->addtestresults( "checkMdiDf() FAILED: could not open socket" );
        return(0);
    }
}
