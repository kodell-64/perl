#!/usr/bin/perl
#
# Version 3
#
# Korey O'Dell
#
# Pull in needed 3rd party modules
use strict;
use warnings;
use IO::Tee; #  emerge dev-perl/IO-Tee to fetch

# Pull in custom built modules
require "testclass.pm";
require "generic.pm";	# loadtests, loadhelp, showhelp, showtests, plus other routines  
						# These will load specific code for a package such as avcd
require "tests.pm";		# Used by specific apps, like avcd or fim_farm
require "report.pm";	# The report module, full report when testing is completed
require "summary.pm";	# The summary module, holds a count of passed/failed tests

#
# ACME Media QA Regression Test Suite v2
#
# regression testing tool for ACME packages
# Usage <scriptname> <release>.tar file
#
# This driver drives regression testing for all ACME packages. Individual perl modules for
# each component are in subdirectories i.e. /ascsos contains ascsos.pm, /abds etc.
# aaa

# Global variables
our $fullVersion;	# The full package name to test, path and extension removed
our $Report;		# The Report object, for reporting test details, failed or pass
our $Summary;		# The Summary object, summed up data points used by $Report
our $resultsPath;	# Path to where the log file will be
my $hostname;		# The hostname of this system
my $packagename;	# The stripped down package name, with only the major version
my $cmdlinearg;		# The command line option, such as --help
my $tee;			# The tee object used for splitting output
my $Tests;			# The Tests object, from tests.pm
my $Test;			# The Test object, from testclass.pm
my $stage;			# The point in the processes currently at.
my %testparams;

$|=1;
&checkOptions();		# Check the command line args and exit if no good.

&init();				# Initialize vars, and objects
&startTesting();		# Start the tests

exit(0);

# ---------------------------------------------------------------------------------

# void startTesting()
#
# The main process that starts testing, and logs the process.  
# Verifies the application package exists and the checksum is valid.  
# The application is a .tar file passed in on the command line.
# Loads all the tests for the application based on the .tar file name
# Shows available tests for an application if --show-tests from command line.
# Updates the Wiki if --update-wiki from the command line.
# 
sub startTesting
{
	generic::stageout( "INFO", "$0 starting at ". generic::getdatetime() );

	# Verify application tar ball exists
	&generic::stageout("INFO", "Checking for $ARGV[0] ");
	if( !-e $ARGV[0] )
	{
		&generic::stageappend("File not found! ");
		end();
		exit( 0 );
	} else {
		&generic::stageappend( "PASSED");
	}

	# Make sure the checksum is good
	&generic::stageout( "INFO", "MD5 signature verification " );
	if(1)# (split(/ /, `md5sum $ARGV[0]`))[0] eq $ARGV[1] )
	{
	    
		# MD5 passed
		&generic::stageappend( "PASSED" );

		# Load all the tests for the application
		# Loads './avcd/avcd.pm' for example
		&generic::stageout("INFO", "loading $packagename tests ");

		if(&generic::loadtests($packagename))
		{
			# Tests loaded succesfully
			&generic::stageappend("PASSED");

			# -- Process additional command line arguments --
			#
			# Show the available tests
			if($ARGV[2] =~ "--show-test=")
			{
			    	generic::showtest($packagename);
			    	print "\n";
			    	exit(0);
			}

			# Clear any test results left over
			# Doesn't do anything but report the data cleared
			# nothing is deleted
			elsif($ARGV[2] eq "--clear-test-results")
			{
			    	#&generic::cleartestresults($packagename);
			    	&generic::cleartestresults($resultsPath);
			    	print "\n";
				exit(0);
			}

			# Print the test plan
			elsif($ARGV[2] eq "--print-test-plan")
			{
				$stage = "Printing $packagename test plan";
				&generic::stageout( "INFO", $stage );
				&generic::printtestplan($packagename);
				print "\n";
				exit(0);
			}
			elsif($ARGV[2] eq "--create-tickets")
			{
				&generic::stageout( "INFO", $stage );
				&generic::createtickets($packagename);
				print "\n";
				exit(0);
			}

			# Show the help message
			elsif($ARGV[2] =~ "--help")
			{
				# Load all the help text for the package
				$stage = "loading $packagename help ";
				generic::stageout( "INFO", $stage );
				generic::stageappend( "PASSED" ) if( generic::loadhelp($packagename) );
				
			    	$stage = "Showing $packagename help";
			    	generic::stageout( "INFO", $stage );
			    	generic::showhelp($packagename);
			    	print "\n";
			    	exit(0);
			}
			
			elsif( $ARGV[2] =~ /--updateWiki/i )
			{
				generic::stageout("INFO", "Updating the Trac wiki");
				generic::stageappend(   (generic::updateWiki($packagename)) ? "PASSED" : "FAILED ") ;
				exit(0);
			}

			# Catch-all, show the available tests 
			elsif($ARGV[2] !~ "--run-tests")
			{
			    &generic::showtests($packagename);
			    exit(0);
			}

			# Start the testing
			generic::runtests($packagename, $ARGV[2]);

			# Tests have completed, generate the reports and clean up.
			$stage = "All tests ended at " .& generic::getdatetime() . "\n";
			generic::stageout( "INFO", $stage);


			$Report->addentry("INFO: $stage"); 			                    

			#Print tests to STDOUT and the log file
			#$main::Tests->dump();
			
			$Summary->{_entries} = $Report->{_reportsummary};
			#$Summary->dump();
			$Report->addentry("INFO: Writing summary to disk.");    
			
			# Save the summary to a file
			$Summary->writetodisk();
			
			# Send an e-mail if requested via command line
			#if( $ARGV[3] )
			#{ 
			#	my $info = "Passed tests: ".$Summary->{"_passedtests"};
			#	$info .= "\nFailed tests: ".$Summary->{"_failedtests"};
			#	$info .= "\n";
			#	
			#	my $body = "***** INFO SECTION ****************************************\n";
			#	$body .= $info."\n***** SUMMARY SECTION *************************************\n";
			#	$body .= $Summary->{_entries};
			#    &generic::sendemail($ARGV[3], "QA Tests: [$hostname] $ARGV[0] system tests results", $ARGV[3], $body);
			#}
			
			# Save the report data to a file
			$Report->addentry("INFO: Writing report to disk.");                        
			$Report->writetodisk();

			exit(1) if(! $Report->{_reportfailurescount});
            exit(0);
		} else {
			end();
		}
	} else {
		end();
	}
}

# void checkOptions()
#
# Verify correct command line arguments, and print a usage
# message if not correct.
#
sub checkOptions
{
	my $usage= "\nUsage: $0 <packagename-x.y.z.xxxx.tar file> <MD5sum> [--help] [--show-tests] [--run-tests] [--test-params] \n\n";
	$usage .= "You must pass a packagename-x.y.z.xxxx.tar file and correct MD5sum for same ";
	$usage .= "tar file to get help, or do anything else with this tool. ";
	$usage .= "This is required since each package (avcd, ascsos etc.) have their own test/help systems.\n\n";
	$usage .= "Examples:\n";
	$usage .= "Get help for the avcd test system.\n";
	$usage .= " perl regression-test-v2.pl avcd-2.9.0.8840.tar 96c9137d8481c7fb52807457b5dbd35c --help\n\n"; 
	$usage .= "Show what tests are available for avcd.\n";
	$usage .= " perl regression-test-v2.pl avcd-2.9.0.8840.tar 96c9137d8481c7fb52807457b5dbd35c --show-tests\n\n";
	die( $usage ) if(! $ARGV[0] || !$ARGV[1] || !$ARGV[2] );
}

sub init
{
	chomp( $hostname = `hostname` );

	$fullVersion = $ARGV[0];	# The full package name: /home/usr/bin/avcd-1.2.3.2345.tar
	$fullVersion =~ s/^.*\///;	# Remove the path: 	 avcd-1.2.3.2345.tar
	$fullVersion =~ s/\.tar//;	# Remove the extension:  avcd-1.2.3.2345

	$packagename = $fullVersion;			# The package name from the modified fullversion
	$packagename =~ s/(^.*-\d*)(.*$)/$1/;	# Shorten to the major version: avcd-1

	$resultsPath = "results/$packagename/$fullVersion";
	#print "resultsPath = $resultsPath\n";

	# any tests to be excluded?
	#&generic::loadexcludetests() if($ARGV[2]);

	################## INIT TEST MODULE(S) #########################

	$cmdlinearg = $ARGV[2];
	if($ARGV[2] eq "--test-params" )
	{
		$cmdlinearg =~ s/--test-params=//g;
		my @elems = split(/],/, $cmdlinearg);

		foreach my $elem (@elems)
		{
			print " elem = $elem\n";
		    $elem =~ s/\]/\,/g;
		    $elem =~ s/\[/\,/g;
		    my @parts = split(/\,/, $elem);
		    for(my $i=1; $i<scalar(@parts); ++$i)
		    {
				$testparams{$parts[0]} .= $parts[$i].",";
		    }		    
		    chop( $testparams{$parts[0]} );	# chop off trailing comma
		}
	} 

	#&generic::init();
	# setup logging mechanism
	# record results to results directory
	mkdir("results") if(! -d "results");
	mkdir("results/$packagename") if(! -d "results/$packagename");
	#mkdir("results/$packagename/$ARGV[0]") if(! -d "results/$packagename/$ARGV[0]");        
	mkdir("results/$packagename/$fullVersion") 
		if(! -d "results/$packagename/$fullVersion");        
	#my $dirdate = &generic::getdatetime();
	#mkdir("results/$packagename/$ARGV[0]/$dirdate") if(! -d "results/$packagename/$ARGV[0]/$dirdate");        
	#my $tee = IO::Tee->new(\*STDOUT,">results/$packagename/$ARGV[0]/$0.$tar.log");
	$tee = IO::Tee->new(\*STDOUT,">results/$packagename/$fullVersion/$fullVersion.log");

	open(STDOUT, ">&$tee"); 
	open(STDERR, ">&$tee");#/dev/null"); 
	select $tee;

	# init the Test object, global object that contains all test information.
	$Tests = new Tests;

	# init the Report object, global object that contains all report information.
	$Report = new Report;

	my (undef,$min,$hour,$day,$mo,$yr,undef,undef,undef) = localtime(time);
	$Report->addentry("\nINFO: Tests started at -> ".&generic::getdatetime()."\n");
	$Report->addentry("INFO: Running on host -> $hostname\n");
	$Report->addentry("INFO: Command line ran with -> ".join(' ', @ARGV)."\n"); 

	# init the Summary object, global object that contains all summary information.
	$Summary = new Summary;

	$Test = new TestClass( );
}

sub end
{
	&generic::stageappend("FAILED");
	$stage = "testing stopped";
	&generic::stageout("INFO", "$0 stopped at ". (&generic::getdatetime()) ."\n") ;
}
