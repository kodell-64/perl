# Korey O'Dell
package TestClass;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep
                    clock stat);
use Data::Dumper;


1;
sub new
{
    my $type = $_[0];   # This class name from inherited sub class
    my $ref  = $_[1];   # This comes in from the applications *test.pm
                        # such as avcdtests.pm or fim_farmtests.pm

   # The class members
   my $self = {
       _testid                  => $ref->{id},
       _testname                => $ref->{name},
       _testdesc                => $ref->{desc},
       _testmode                => $ref->{mode},
       #_edgetestmode           => $ref->{edgetestmode},
       _testnarrative           => $ref->{narrative},
       _testtype                => $ref->{testtype},    
       _prerunactions           => $ref->{prerunactions},   # V3
       _startactions            => $ref->{startactions},    # V3
       _runactions              => $ref->{runactions},      # V3
       _postrunactions          => $ref->{postrunactions},  # V3
       _stopactions             => $ref->{stopactions}, # V3
       _configpreset            => $ref->{configpreset},    # V3
       _runloop                 => ($ref->{runloop}) ? $ref->{runloop} : 1 ,            # V3
       _multipass               => $ref->{multipass},
       _srcfile                 => ($ref->{srcfile}) ? $ref->{srcfile} : $ref->{src} ,  # V3 : V2
       _wantedpids              => $ref->{wantedpids},
       _scramblemode            => $ref->{scramblemode},
       _scramblepercentage      => $ref->{scramblepercentage},
       _dstfile                 => $ref->{dstfile},
       _path                    => $ref->{path},
       _operationmode           => $ref->{operationmode},
       _vodxproccommandline     => $ref->{vodxproccommandline},
       _ecmgcommandline         => $ref->{ecmgcommandline},
       _commandline             => $ref->{commandline},
       _ecmghost                => $ref->{ecmghost },
       _gkurl                   => $ref->{gkurl},
       _acn                     => $ref->{acn},
       _multipass               => $ref->{multipass},
       _remotehost              => $ref->{remotehost},
       _puturl                  => $ref->{puturl},
       _videofile               => $ref->{videofile},
       _ecmgport                => $ref->{ecmgport},
       _macaddr                 => $ref->{macaddr},
       _wantedegresses          => $ref->{wantedegresses},
       _keyid                   => $ref->{keyid},
       _channel                 => $ref->{channel},
       _key                     => $ref->{key},
       _vod                     => $ref->{vod},
       _ecmgkeys                => $ref->{ecmgkeys},
       _asset                   => $ref->{asset},
       _vodxproclogpath         => $ref->{vodxproclogpath},
       _logpath                 => $ref->{logpath},
       _logerror                => $ref->{logerror},
       _ecmglogpath             => $ref->{ecmglogpath},
       _codeword                => $ref->{codeword},
       _srcaddr                 => ($ref->{srcaddr}) ? $ref->{srcaddr} : $ref->{srcaddr} ,  # V3 : V2
       _dstaddr                 => ($ref->{dstaddr}) ? $ref->{dstaddr} : $ref->{dstaddr} ,  # V3 : V2
       _slatefile               => $ref->{slatefile},
       _assetfile               => $ref->{assetfile},
       _resultspath             => $ref->{resultspath},
       _encodefile              => $ref->{encodefile},
       _capture                 => "",
       _filetofilemode          => $ref->{filetofilemode},
       _pretend                 => $ref->{pretend},
       #WebDav
       _csdsurlput              => $ref->{csdsurlput},
       _csdsurlget              => $ref->{csdsurlget},
        
       #_testextra1             => $ref->{extra1},
       #_testextracmds          => $ref->{extracmds},
       #_testedgeconfadditions  => $ref->{edgeconfadditions},
       #_testhe_egress_pids     => $ref->{he_egress_pids},
       #_testedge_egress_pids   => $ref->{edge_egress_pids},
       _teststeps               => $ref->{teststeps},
       _steps               => $ref->{steps},
       #_testcaptureproxybinary => $ref->{captureproxybinary},
       #_testfuncpointer        => $ref->{funcpointer},
       #_testsrc                => $ref->{src},
       #_testsrcaddress         => $ref->{srcaddress},
       _edgetestmode            => "",
       _testextra1              => "",
       _testextracmds           => "",
       _testconfiguration       => $ref->{configuration},
       _filename                    => $ref->{filename},
       _preset                    => $ref->{preset},
       _startingrow                    => $ref->{startingrow},
       _dbcredentials           => $ref->{dbcredentials},
       _vihostpath           => $ref->{vihostpath},
       _numtitleids             => 0,
       _titleids                => [],
       _testedgeconfadditions   => "",
       _testhe_egress_pids      => "",
       _testedge_egress_pids    => "",
       _testbinpath             => "",
       _testresults             => "",
       _testtimestart           => "",
       _testtimeend             => "",
       _starttime               => "",
       _stoptime                => "",
       _testfailed              => "",
       _testcaptureproxybinary  => "",
       _testfuncpointer         => "",
       _testparams              => {},
       _testsrc                 => "",
       _testsrcaddress          => "",
       _testwarningscount       => 0,
       _testfailurescount       => 0,
       _testfailuresresults     => [],
       _testpassesresults       => [],
       _testwarningsresults             => [],
       _testhe_egress_additional_pids   => "",
       _testedge_egress_additional_pids => "",
       #_testedge_egress_additional_pids => $ref->{edge_egress_additional_pids},
       #_testhe_egress_additional_pids => $ref->{he_egress_additional_pids},
   };
   
   $self->{_srcfile} = "" if( !defined($self->{_srcfile}) );

   return bless $self, $type;   
}

# void starttest()
#
# Starts logging of the current test, and initializes some globals
#
# Arguments: none
# Returns: void

sub starttest
{
    my ($self) = @_;
    $self->{_testtimestart} = time;
    $self->addtestresults("****************************************************************************");
    $self->addtestresults("******* Starting => [".$self->{_testid}."] [".$self->{_testname}."] *******");
    $self->addtestresults("****************************************************************************");
    $self->addtestresults("Starting test \@ ".localtime($self->{_testtimestart})." :INFO");
    $self->addtestresults("Narrative for test: ".$self->{_testnarrative});
    my $line = "Running with additional parameters: ";
    my $k;
    my $v;
    while( ($k,$v) = each %{$self->{_testparams}})
    {
        $line .= "$k=$v ";
    };
    $self->addtestresults($line);

    # init these to blank
    $memorystats = {};
    $processstats = {};    

}



sub endtest
{
    my ($self) = @_; 
    # Clean up sub processes
    $self->addtestresults("waiting for child processes to exit: ".join(",", @children) );
    foreach ( @children )
    {
        waitpid( $_, 0 );
    }
    $self->addtestresults("children have exited");
    $self->{_testtimestop} = time;
    $self->addtestresults("Test had [".$self->{_testwarningscount}."] warnings :INFO");
    $self->addtestresults("Test had [".$self->{_testfailurescount}."] failures :INFO");
    $self->addtestresults("*******************************************************************************************");
    $self->addtestresults("******* Ending => ".$self->{_testname});
    $self->addtestresults("*******************************************************************************************");
    $self->addtestresults("Ending test \@ ".$self->{_testtimestop}." :INFO");

    if(! $self->{_testparams}->{'pretend'})
    {
        my $dir = "failed";
        $dir = "passed" if(!$self->{_testfailurescount});
        my $path = "results/$self->{_packagename}/$main::fullVersion.tar/";
        # remove old runs
        if($dir eq "failed")
        {
            unlink $path."test-".$self->{_testid}."-passed.txt";
            unlink $path."test-".$self->{_testid}."-wiki-passed.txt";
        }
        else
        {
            unlink $path."test-".$self->{_testid}."-failed.txt";
            unlink $path."test-".$self->{_testid}."-wiki-failed.txt";
        }

        `mkdir -p $path` if(! -e $path);
        my $wikipath = $path."test-".$self->{_testid}."-wiki-$dir.txt";
        
        $path .= "test-".$self->{_testid}."-$dir.txt";
        $self->addtestresults("Writing individual test results to $path");
        &writetestresults($self, $path);

        $self->addtestresults("Writing individual test wiki results to $wikipath");
        open(FH, ">$wikipath");
        my $color = "red";
        my $pf = "Failed";
        if(!$self->{_testfailurescount})
        {
            $color = "green";
            $pf = "PASS";
        }
        print FH "=== !\#".$self->{_testid}."] [".$pf."]".$self->{_testname}." ===\n";
        print FH " * [[Color($color, $pf)]]\n";
        my $tester;
        $tester = ($ARGV[3]? $ARGV[3] : "QA");
        print FH " * Test Narrative: ".$self->{_testnarrative}."\n";
        print FH " * ran by: $tester \@ ".localtime(time)."\n";
        print FH " * Test Results\n";
        print FH "{{{";
        
        print FH "\n".join("", @{$self->{_testpassesresults}}) if( scalar( @{$self->{_testpassesresults}}) );
        print FH "\n".join("", @{$self->{_testwarningsresults}}) if( scalar( @{$self->{_testwarningsresults}}) );
        print FH "\n".join("", @{$self->{_testfailuresresults}}) if( scalar (@{$self->{_testfailuresresults}}) );
        print FH "\n".join("", @{$self->{_testinfosresults}}) if( scalar (@{$self->{_testinfosresults}}) );
        
        print FH "\n}}}";
        close FH;
        $self->addtestresults("scping individual test wiki results to avail\@192.168.20.25:qa/regression-test-v3/results/$self->{_packagename}/$main::fullVersion.tar");

        my $path = "results/$self->{_packagename}/$main::fullVersion.tar";
        open(FH, ">$path/lasttest.txt");
        print FH time;
        close FH;
        
        #`ssh -p2222 avail\@localhost mkdir -p qa/regression-test-v3/results/$self->{_packagename}/$main::fullVersion.tar`;
        #`ssh -p2222 avail\@localhost mkdir -p qa/regression-test-v3/results/$self->{_packagename}/$main::fullVersion.tar`;
        `scp -P2222 $path/lasttest.txt $wikipath avail\@10.1.2.166:qa/regression-test-v3/results/$self->{_packagename}/$main::fullVersion.tar`;
        `scp -P2222 $path/lasttest.txt $wikipath avail\@10.1.2.166:qa/regression-test-v3/results/$self->{_packagename}/$main::fullVersion.tar`;
         return;
    }
    return;
}


sub writetestresults
{
    my ($self, $path) = @_;
    open(FH, ">$path");
    print FH $self->{_testresults};
    close FH;
}

sub manualTest
{
    my ( $self ) = @_;
    my $ret = 0;
    $self->addtestresults( "manualTest: started" );
    my $i = 1;
    my $passes = 0;
    my $status = "FAIL";
    foreach my $step (@{$self->{_teststeps}})
    {
        $self->addtestresults( $i."] $step (P(p)ASS/F(f)AIL)?" );
        my $response = <STDIN>;
        chomp $response;
        
        if(lc($response) eq "f")
        {
            $self->addtestresults( $i."] $step : FAIL" );
            #$self->addtestresults( $i."] : FAIL" );
        }
        elsif(lc($response) eq "q")
        {
            exit;
        }
        else 
        {
            $self->addtestresults( $i."] $step : PASS" );
            #$self->addtestresults( $i."] : PASS" );
            ++$passes;
        }
        ++$i;
    }
    
    if(scalar(@{$self->{_teststeps}}) == $passes)
    {
        #$self->addtestresults("\tmanualTest: PASS");
        $status = "PASS";
        $ret = 1;
    }
    else
    {
        #$self->addtestresults("\tmanualTest: FAIL");
    }
    $self->addtestresults( "manualTest: End of Test Notes? (:q to end)\n" );
    
    my $response_txt;
    system("vi -c 'startinsert' -c 'set paste' /tmp/test.txt");
    open FILE, "/tmp/test.txt";
    my @response = <FILE>;
    foreach my $res (@response)
    {
            $response_txt .= $res;
    }
    unlink("/tmp/test.txt");
    
   $self->addtestresults( "manualTest: End of Test Notes: $status\n\n$response_txt" );

    $self->addtestresults( "manualTest: ended" );
    return $ret;
}

sub dumptest
{
    my ( $self ) = @_;
    print "\n**** ".$self->{_testname}." Dump() ****\n";
    print Dumper($self);
}

sub dumpresults
{
    my ( $self ) = @_;
    print "\n**** ".$self->{_testname}." ****\n";
    print $self->{_testresults}."\n";
}

sub addtestresults
{
    my ( $self, $results ) = @_;
    my $resp = &generic::stageout($self->{_testid}, $results);#$self->{_testname}, $results);
    $self->{_testresults} .= $resp;
    if($results =~ /\*\*\*/)
    {
        push @{$self->{_testinfosresults}}, $resp;
    }
    elsif($results =~ /PASS/)
    {
        ++$self->{_testpassesscount};
        push @{$self->{_testpassesresults}}, $resp;
    }
    elsif($results =~ /WARNING/)
    {
        ++$self->{_testwarningscount};
        push @{$self->{_testwarningsresults}}, $resp;
    }
    elsif($results =~ /FAIL\b/ || $results =~ /FAILED\b/)
    {
        ++$self->{_testfailurescount};
        push @{$self->{_testfailuresresults}}, $resp;
    }
    elsif($results =~ /INFO/)
    {
        ++$self->{_testinfoscount};
        push @{$self->{_testinfosresults}}, $resp;
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
        }
        $elapsed = tv_interval($t1, [gettimeofday]);
        nanosleep(100);
    }while($elapsed < $seconds);
    ReadMode 0; # Reset tty mode before exiting
    $self->addtestresults( "Waking up main program, $seconds seconds has passed" );
    return(1);
}

sub oldpaused
{
    use Term::ReadKey;
    my( $self, $seconds ) = @_;
    $self->addtestresults( "Pausing main program for $seconds seconds (hit 's' to stop, 'f' to fail test)" );

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
            if($key eq "s")
            {
                $self->addtestresults( "pause(): user has stopped test manually: PASSED" );
                ReadMode 0; # Reset tty mode before exiting
                return 0;
            }
        }
        $elapsed = tv_interval($t1, [gettimeofday]);
        nanosleep(100);
    }while($elapsed < $seconds);
    ReadMode 0; # Reset tty mode before exiting
    $self->addtestresults( "Waking up main program, $seconds seconds has passed" );
    return(1);
}
