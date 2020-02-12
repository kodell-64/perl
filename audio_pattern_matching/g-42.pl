#!/usr/bin/perl
#use strict;
use Data::Dumper;
use Math::FFT;
use Math::Round;
#use Bit::Compare;
use DBI;
use Text::Levenshtein qw(distance);
use List::Util qw(sum);
use Inline C;
$| = 1;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep
		      clock_gettime clock_getres clock_nanosleep clock
                      stat );
local $deep_scan_enabled=0;
local $drilldown_enabled=1;
local @skips=(-2048, -1024, -512, -256, 0);#, 512, 1024, 2048);#-1024,-512,0,512,1024);#;#=(-640);#-512, -256, 0);#(-756, -640, -512, -384, -256, -128, 0);#=(256,2048+256);#(-2048, -1024, -768, -512, 0);#-2048-768, -512,0,512, 768);#(-1024, -768, -512, 0, 512, 768, 1024);#-1024);#-1024);#,-512);#,-512,0);#-1024, -512, 0, 512, 1024);#(-1024, 0, 1024);#, -512, 0, 512, 1024);#32,-128);#(0,32,256,512,1024);#863#(0,32,64,256,512,1024,2048);#(0,8,32,2048);#(0,8,32,64,512,1024,2048);
use Time::Local;
my $dbh = DBI->connect("DBI:mysql:database=audible;host=127.0.0.1",
                    "mt", "*****",
                    {'RaiseError' => 1});
if(! $dbh) { die "No db connection" }

`mkdir log` if(! -e "log");
open(LFH, ">>log/$0.log") || die $_;

#@skips=(1306);#
my $ffmpeg = "/usr/bin/ffmpeg";
my $ccextractor = "/usr/local/bin/ccextractor";

# processor
# need table in db to maintain record of processing
my $buckets; my $freqs;
my $path= "content";
&log("starting up...");

&log("reading in ads to memory...");
my $ads; my $adcount=0;
my $sql = "select * from ads";
my $sth = $dbh->prepare($sql);
$sth->execute( );
my $ref = $sth->fetchrow_hashref();
while($ref)
{
    $ads->{$ref->{id}}->{description} = $ref->{description};
    $ads->{$ref->{id}}->{length} = $ref->{length};
    $ads->{$ref->{id}}->{cc_data} = $ref->{cc_text};
    ++$adcount;
    $ref = $sth->fetchrow_hashref();
}
&log("read in [$adcount] ads...");

print "\nreading in all ad chunks...";
# read in all ads
my $sql = "select * from ad_chunks;";
my $sth = $dbh->prepare($sql);
$sth->execute( );
my $ref = $sth->fetchrow_hashref();
my $ad_tip_tail;
my $c_ad_id = undef;
my $l_chunk; my $l_ad_id;
while($ref)
{
    if($c_ad_id eq undef)
    {
        $ad_tip_tail->{$ref->{ad_id}}->{tip} = $ref->{id};
        $c_ad_id = $ref->{ad_id};
    }
    if( $c_ad_id != $ref->{ad_id} )
    {
        $ad_tip_tail->{$l_ad_id}->{tail} = $l_chunk;
        $c_ad_id = undef;
    }
    $main::ad_chunks->{$ref->{id}}->{ad_id} = $ref->{ad_id};
    $freqs->{$ref->{id}}=$ref->{freqs};

    #push @{$buckets->{$ref->{bucket_0}}->{chunk_ids}}, $ref->{id};
    #push @{$buckets->{$ref->{bucket_0}}->{freqs}}, $ref->{freqs};
    my $b_string;
    for(my $i=0;$i<=7;++$i)
    {
        push @{$buckets->{"bucket_$i"}->{$ref->{"bucket_$i"}}}, $ref->{id};
        $b_string .= " $i:".$ref->{"bucket_$i"};
        $chunks->{$ref->{id}}->{"bucket_$i"}->{$ref->{"bucket_$i"}} = 1;
    }
    #&log($b_string);
    
    $l_chunk = $ref->{id};
    $l_ad_id = $ref->{ad_id};
    $ref = $sth->fetchrow_hashref();
    if(!$ref)
    {
        $ad_tip_tail->{$l_ad_id}->{tail} = $l_chunk;
    }
}

#print Dumper $buckets;#ad_tip_tail;
print "\ndone";

@main::ad_chunks = sort { $a <=> $b } keys %{$main::ad_chunks};

while(1)
{

    # lock content table
    my $locked = 0;
    while($locked)
    {
        my $sql = "select * from system where `table`=?";
        my $sth = $dbh->prepare($sql);
        $sth->execute( "content" );
        my $ref = $sth->fetchrow_hashref();
        $locked = $ref->{lock};
        if($locked) { &log("content table locked, waiting..."); sleep 1 }
    }

    # lock table
    my $sql = "update system set `lock`=? where `table`=?";
    my $sth2 = $dbh->prepare($sql);
    $sth2->execute( 1, "content" );
    $locked = 1;
    #&log("locked content table...");

    # first look for content that has not been processed
    my $sql = "select * from content where ready_to_process is not null limit 1";
    my $sth = $dbh->prepare($sql);
    $sth->execute( );
    my $ref = $sth->fetchrow_hashref();
    # unlock table
    my $sql = "update system set `lock`=? where `table`=?;";
    my $sth2 = $dbh->prepare($sql);
    $sth2->execute( undef, "content" );
    #&log("unlocked content table...");
    my $scans;
    my $doit = undef;
    if($ref)
    {
        &log("content_id[$ref->{content_id}] new content has arrived...");
        ++$doit;
    }
    if(!$doit && $deep_scan_enabled)
    {
        my $sql = "select * from content where processed=1 and scans < 5 limit 1";
        my $sth = $dbh->prepare($sql);
        $sth->execute( );
        $ref = $sth->fetchrow_hashref();
        if($ref)
        {
            &log("content_id[$ref->{content_id}] reprocessing content scans[$ref->{scans}]...");
            $scans = $ref->{scans};
            #build skips
            my @new_skips;
            #local @skips=(-2048, -1024, -512, -256, 0)

            foreach my $skip(@skips)
            {
                push @new_skips, ($skip - 2**($scans*2))
            }
            @skips = @new_skips;
            ++$doit;
        }
    }
    if($doit)
    {
        my $et = time;
        my $content_id = $ref->{id};
        my $channel_id = $ref->{channel_id};
        my $raw_filename = $ref->{raw_filename};
        if(-e "$path/$raw_filename")
        {
            my $sql = "update content set ready_to_process=?, processing=?, processed=?, elapsed_time=? where id=?;";
            my $sth = $dbh->prepare($sql);
            $sth->execute( undef, 1, undef, $et, $ref->{id});
            &log("content_id[$content_id]: skips are ".join(",", @skips));
            &log("content_id[$content_id]: processing content for $raw_filename");
            my $et = time;
        
            my $suspects;
            my @ad_bitstrings;
            my @target=();
            my $bytes=undef;
            my $audio_data;
            
            &log( "content_id[$content_id]: reading in content data ($path/$raw_filename) to memory...");
            open(FH, "<$path/$raw_filename") || die $_;
            binmode FH;
            my $seconds = 0;
            my $bytes;
            my $a1 = read FH, $bytes, 16384*4; # one second of audio at 16khz
            while($a1)
            {
                $audio_data .= $bytes;
                $a1 = read FH, $bytes, 16384*4;
            }
            close FH;

            &log("content_id[$content_id]: done... size of audio data: ".length($audio_data));

            # fom this we will have suspects, populated with frames 
            foreach my $skip (@skips)
            {
                $main::frame = 0;    
                # idea is to multipass audio data, offset=0, offset=64, 512 etc.
                my $index = 0;
                my $len = length($audio_data);
                my $i = $skip;
                while( $i < $len )
                # for(my $i=0;$i<$len;$i+=2048)
                {
                    if( ($i+2048) <= $len )
                    {
                        my $chunk;
                        if($i >= 0)
                        {
                            $chunk = substr($audio_data, $i, 2048);
                            #$chunk = substr($audio_data, ($i+$skip), 2048)
                            &analyze_chunk($chunk, $skip, \%{$suspects});
                        }
                        ++$main::frame;
                        #print "\nskip [$skip] i [$i] frame: $main::frame";
                        print "\nskip [$skip] $main::frame";
                    }
                    #last if( ($main::frame > 3000));
                    if( ($main::frame % 1000) == 0)
                    {
                        &log("content_id[$content_id]: skip [$skip] frame: $main::frame")
                    }
                    $i += 2048;
                }
            }
            
            &log("content_id[$content_id]: done processing...");

            # COMBINE SCANS
            # OUT OF SUSPECTS COMES SUSPECT
            # out of suspects, we will have likelys
            # need to handle case where the same ad appears multiple times in a chunk


            &log("content_id[$content_id]: find tip/tail of ads...");

            
            # ROUND 1 INTERROGATION
            # FIND TIP AND TAIL FRAMES FOR EACH AD
            # MAKE LIST OF LIKELY ADS
            my @ad_ids = sort { $a <=> $b} keys %{$suspects};

            &log("ad ids in suspects:".scalar(@ad_ids));

            my $ad_ids;
            foreach my $ad_id (@ad_ids)
            {
                $ad_ids .= "[$ad_id] ";
            }
            &log("content_id[$content_id]: suspect ad_ids $ad_ids");

            my $candidates = &scan_suspects($suspects, @ad_ids);
        

            # let's check and see if it is already there i.e. we've already
            # scanned this content. If it is, dont waste time
            # to toss it.
            &log("checking for ads we've already identified...");
            my @ad_ids = sort { $a <=> $b } keys(%{$candidates});
            foreach my $ad_id (@ad_ids)
            {
                my @skips = sort { $a <=> $b} keys %{$candidates->{$ad_id}};
                my $i=1;
                foreach my $skip (@skips)
                {
                    my @tipfs = sort { $a <=> $b} keys %{$candidates->{$ad_id}->{$skip}};
                    foreach my $keyframe (@tipfs)
                    {
                        my $start = $candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_frame};
                        my $end = $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame};
                        my $sql = "select id from suspect_ads where ad_id=? and content_id=? and tip_frame >= ? and tip_frame <= ?;";
                        my $sth = $dbh->prepare($sql);
                        my @vals = ($ad_id, $content_id, ($start-500), ($start+500) );
                        $sth->execute( @vals );
                        &log("sql: $sql");
                        &log("vals: ".join(",", @vals));
                        $ref = $sth->fetchrow_hashref();
                        #TODO IF TIP/TAIL FRAMES ARE BETTER WE COULD USE THE DATA
                        if($ref)
                        {
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] keyframe[$keyframe] NOT inserting ad, already found it.");
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] keyframe[$keyframe] removing ad_id[$ad_id] from candidates.");
                            delete $candidates->{$ad_id}->{$skip}->{$keyframe};
                        }
                    }
                }
            }

            print "\ncandidates";
            print Dumper $candidates;
            &log("drilldown on ads we've identified...");
            # DRILLDOWN
            # WE'VE got ad_id and know where the ad is in the data
            # find the first ten frames in the content
            if($drilldown_enabled)
            {
                my @ad_ids = sort { $a <=> $b } keys(%{$candidates});

                foreach my $ad_id (@ad_ids)
                {
                    my @skips = sort { $a <=> $b} keys %{$candidates->{$ad_id}};
                    my $i=1;
                    foreach my $skip (@skips)
                    {
                        my @tipfs = sort { $a <=> $b} keys %{$candidates->{$ad_id}->{$skip}};
                        foreach my $keyframe (@tipfs)
                        {
                            my $best_hit = 0; my $best_i=0;
                            my $index = 0;
                            my $tip = $candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_frame};
                            my $tail = $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame};
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] tip_frame[$tip] tail_frame[$tail] let's do some mining...");
                            my $new_suspect;
                            my $tip_chunk_id;
                            my $ad_length = $ads->{$ad_id}->{length};
                            my $in_frames = $ad_length*8;
                            my $start = ($tip-$in_frames);
                            $start = 0 if($start < 0);
                            my $ad_data = substr($audio_data, ($start*2048)+$skip, $ad_length*8*2*2048);
                            #open(FH, ">audio.raw");
                            #print FH $ad_data;
                            #close FH;
                            my $len=length($ad_data);


                            my $ad_tip = $ad_tip_tail->{$ad_id}->{tip};
                            #&log("ad_tip: $ad_tip");
                            my @freqs;
                            for(my $i=0;$i<$in_frames;++$i)
                            {
                                push @freqs, $freqs->{$i+$ad_tip}
                            }
                            #&log("freqs0 ".$freqs[0]);
                            #print Dumper @freqs;
                            #   $freqs->{$ref->{id}}=$ref->{freqs};
                            my $best_skip = 0;
                            my $best_tip = 2**32; my $best_tail = 0;
                            my $best_hits = undef;
                            #for(my $s=448;$s<=448;$s+=64)
                            #for(my $s=(-256+0);$s<(256+0);$s+=1)
                            for(my $s=(-512+0);$s<(512+0);$s+=64)
                            {
                                my $frame = 0;
                                my $hits = 0;

                                my @frames;
                                for(my $i=0;$i<$len;$i+=2048)
                                {
                                    if( ($i+$s) > 0 &&
                                        ($i+$s+2048) <= $len )
                                    {
                                        my $chunk = substr($ad_data, ($i+$s), 2048);
                                        #&analyze_chunk_by_ad($chunk, ($i+$s), \%{$new_suspect}, $ad_id);              
                                        my $bs = &get_bitstring($chunk);
                                        if($bs)
                                        {
                                            for(my $i=0;$i<$in_frames;++$i)
                                            {
                                                my $match = c_cmp($bs, $freqs[$i]);
                                                if($match >= 442)
                                                {
                                                    &log("content_id[$content_id] skip[$skip\+$s] ad_id[$ad_id]: skip: ".($s)." frame: $frame got a hit $match again chunk $i");#\n$bs\n$freqs[$i]")
                                                    push @frames, ($start+$frame); # adjust frame #

                                                }
                                            }
                                        }
                                        ++$frame;
                                    }
                                }
                                # ok now we've got the set of frames, check for delta 
                                # and alignment with chunks
                                # set tip,tail and best_skip when done
                                #my $ad_tip =; my $ad_tail =;
                                my $tip = undef; my $tail = undef;
                                my $t_frames = scalar(@frames);
                                my $frames_ahead = 5;
                                for(my $i=0;$i<scalar(@frames);++$i)
                                {
                                    &log("frame: $frames[$i]");
                                    if($tip eq undef)
                                    {
                                        # validate frame as possible tip
                                        # must have seq run of frames
                                        my $delta = 0; 
                                        my $remainder = ($t_frames - $i);
                                        $remainder = $frames_ahead  if($remainder > $frames_ahead); 
                                        for(my $j=($i+1);$j<($i+1+$remainder);++$j)
                                        {
                                            $delta += ($frames[$j] - $frames[$j-1]);
                                            if( $frames[$j] > $frames[$j-1])
                                            {
                                                ++$hits
                                            }
                                        }
                                        
                                        if($hits == $remainder && ($delta > 0 && $delta < 20)) 
                                        {
                                            if( $remainder >= $frames_ahead )
                                            {
                                                &log("content_id[$content_id] skip[$skip] ad_id[$ad_id]: drilldown setting tip to $frames[$i]");
                                                $tip=$frames[$i]
                                            }
                                        }
                                    }
                                    $tail = $frames[$i];
                                    $best_skip = $s;
                                }
                                if($tip && $tip < $best_tip)
                                {
                                    &log("content_id[$content_id] skip[$skip] ad_id[$ad_id]: setting best_tip to tip:$tip best_tip:$best_tip");
                                    $best_tip = $tip;
                                }

                                
                                $best_tail = $tail if($tail>$best_tail);
                                $best_hits = $hits if($hits>$best_hits);
                                &log("**********************************");
                            }

                            if( $best_tail > ($best_tip+($ad_length*8)))
                            {
                                &log("content_id[$content_id] skip[$skip] ad_id[$ad_id]: drilldown: adjusting best_tail[$best_tail] to (best_tip+length of ad) => $best_tip \+ ".($ad_length*8)." = ".($best_tip+($ad_length*8)));
                                $best_tail = ($best_tip+($ad_length*8));
                            }
                            # need to adjust tip relative to start
                            #$best_tip += $start if($start >= 0);
                            #$best_tail += $start if($start >= 0);
                            
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id]: drilldown: max hits was $best_hits for skip: $best_skip best_tip:$best_tip best_tail:$best_tail best_start: $best_start");

                            #  if the tip of the orig scan is better than, use it
                            if($candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_frame} > $best_tip)
                            {
                                &log("content_id[$content_id] skip[$skip] ad_id[$ad_id]: drilldown: changing tipframe $candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_frame} <=> $best_tip");
                                $candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_frame} = $best_tip;
                            }
                            # no -just set tail frame to ad_len + tip
                            # set it to the best tail found, when we cut we'll take ad_len
                            $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame} = $best_tail;
                            #$candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame} = ($best_tip + ($ad_length*8));

                            if(0 && $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame} > ($best_tip + ($ad_length*8)))
                            {
                                &log("content_id[$content_id] skip[$skip] ad_id[$ad_id]:drilldown: changing tailframe $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame} <=> $best_tail");
                                $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame} = $best_tip + ($ad_length*8);
                            }
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id]: tip_frame: $candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_frame} tail_frame: $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame}");
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id]: drilldown: done");
                        }
                    }
                }
            }
            
            my @ad_ids = sort { $a <=> $b } keys(%{$candidates});

            foreach my $ad_id (@ad_ids)
            {
                my @skips = sort { $a <=> $b} keys %{$candidates->{$ad_id}};
                my $i=1;
                foreach my $skip (@skips)
                {
                    my @tipfs = sort { $a <=> $b} keys %{$candidates->{$ad_id}->{$skip}};
                    foreach my $keyframe (@tipfs)
                    {
                        my $t=time;
                        my $tipf = $candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_frame};
                        my $tailf = $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame};
                        my $start; my $end;
                        
                        my $total_frames = $candidates->{$ad_id}->{$skip}->{$keyframe}->{total_frames};
                        my $average = $candidates->{$ad_id}->{$skip}->{$keyframe}->{average};
                        
                        my $cc_data_match = 0;
                        my $sql = "select ts_filename, start_time from content where id=?;";
                        my $sth = $dbh->prepare($sql);
                        $sth->execute( $content_id );
                        my $ref = $sth->fetchrow_hashref();                
                        my $ts_file = $ref->{ts_filename};
                        my $content_start_time = $ref->{start_time};  
                        my $cc_data = undef;

                        my $mp4_file;
                        my $s_ts_file;
                        my $jpg_file;
                        if(1) # cut suspected ads to disk
                        {
                            my $startat = ($tipf/8) - 0;
                            my $endat = ($tailf/8) - $startat;
                            $mp4_file = $content_id."_".$ad_id."_$i.mp4";
                            $s_ts_file = $content_id."_".$ad_id."_$i.ts"; 
                            `mkdir suspect_ads` if(! -e "suspect_ads");
                            my $cmd = "$ffmpeg -loglevel error -y -ss $startat -i $path/$ts_file -t $endat -vcodec libx264 -g 1 -x264opts keyint=1:min-keyint=1:scenecut=-1 -vb 1000k -s cif -acodec aac -strict -2 -ab 96k -ac 2 -ar 48000 suspect_ads/$mp4_file 2>&1 >/dev/null";
                            system($cmd);
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] cut ad with '$cmd'...");
                            
                            my $cmd = "$ffmpeg -y -ss ".($startat-1)." -i $path/$ts_file -t $endat -vcodec copy -acodec copy cc_data/$s_ts_file 2>&1 >/dev/null";
                            system($cmd);
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] cut ts for cc extraction with '$cmd'...");
                            
                            $jpg_file = $content_id."_".$ad_id."_$i.jpg"; 
                            ++$i;
                            
                            my $jstartat = $startat;
                            my $cmd = "$ffmpeg -loglevel error -y -ss $jstartat -i $path/$ts_file -vframes 1 -s 352x288 -f image2 suspect_ads/$jpg_file";
                            system($cmd);
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] jpg for suspected ad cut with '$cmd'...");
                        }
                        
                        if($ads->{$ad_id}->{cc_data} ne "none available")
                        {
                            # look at suspect ads, match up cc text
                            # to do so we have the ad id, we need to seek into the ts and extract the cc text from
                            # the suspect ad
                            # do a levinstiegel match and make a determination
                        
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] cmp'ing cc_data for ad_id $ad_id...");
                            my $cmd = "$ccextractor cc_data/$s_ts_file -out=txt -lf -o cc_data/${ad_id}.cc 2>&1 > /dev/null";
                            &log($cmd);
                            system($cmd);
                            
                            open(FH, "<cc_data/${ad_id}.cc");
                            my $line = <FH>;

                            while($line)
                            {
                                $cc_data .= $line;
                                $line = <FH>
                            }
                            close FH;
                            $cc_data =~ s/[^a-zA-Z0-9 _'",\x0a\x0d\.\!-]//g;
                            &log("ccdata $ads->{$ad_id}->{cc_data}, $cc_data");
                            my $len = length( $ads->{$ad_id}->{cc_data} );
                            my $diff = distance( $ads->{$ad_id}->{cc_data}, $cc_data );
                            #$diff = $len if($diff > len);
                            $cc_data_match = int(100*(($len-$diff)/$len));
                            #&log("cmp diff: $diff len of ad cc_data: $len len of suspect cc_data: ".length($cc_data));
                        }

                        
                        # if cc data present and not better than 75% match, toss ad
                        if(0 && $ads->{$ad_id}->{cc_data} ne "none available"
                           && $cc_data_match < 75)
                        {
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] discarding ad - too low of cc match $cc_data_match%")
                        }
                        else
                        {
                            
                            my $aired = int(($tipf/8) + $content_start_time);
                            my $sql = "insert into suspect_ads values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] inserting suspect ad with ad:id $ad_id keyframe[$keyframe] total_frames[$total_frames] description[$ads->{$ad_id}->{description}]");
                            
                            #&log("inserting into ads_aired table ad_id: $ad_id desc: ".$report->{$ad_id}->{description});
                            my @vals = ( undef, $ad_id, $channel_id, 
                                         $content_id,
                                         $cc_data,
                                         $aired,
                                         $keyframe,
                                         $tipf, $tailf,
                                         undef, undef,
                                         $skip,
                                         $average,
                                         $cc_data_match, undef, $mp4_file, $t);
                            
                            my $sth = $dbh->prepare($sql);
                            $sth->execute( @vals );
                            &log("sql: $sql");
                            &log("sql-vals: ".join(", ", @vals));
                            # test table
                            my $sql = "insert into test_content values (?, ?, ?, ?);";
                            my $sth = $dbh->prepare($sql);
                            my @vals = (undef, $content_id,
                                        $ad_id, $t);
                            $sth->execute( @vals );
                        }
                    }
                }
            }
        }
        my $t = time;
        $et = $t - $et;
        my $sql = "update content set processing=?, processed=?, elapsed_time=?, completed_processing=?, scans=? where id=?;";
        ++$scans;
        my $sth2 = $dbh->prepare($sql);
        $sth2->execute( undef, 1, $et, $t, $scans, $content_id);
        print "\nupdated db $ref->{id}...";sleep 5;            
        #$ref = $sth->fetchrow_hashref();

    }
    else
    {
        &log("no new content to process and all existing content has been scanned repeatedly...");
    }
    &log(".");
    sleep 1;
}


#print Dumper $report;
#print "\n\n";

sub scan_suspects
{
    my ($suspects, @ad_ids) = @_;
    my $candidates;
    my $frames_ahead = 3; # was 5
    foreach my $ad_id (@ad_ids)
    {
        foreach my $skip (@skips)
        {
            my @frames = sort { $a <=> $b} keys %{$suspects->{$ad_id}->{$skip}->{frames}};
            if(1)
            {
                my $hits = 0;
                foreach my $frame(@frames)
                {
                    ++$hits if($frame >=8096 && $frame<=8576);
                    print "\nf: [$ad_id] [$skip] $frame"
                        
                }
                #print "\ntotal frames: $hits";
                #print Dumper @frames;
                #next;
            }
            my $ad_len = $ads->{$ad_id}->{length};
            my $i=0;
            my $t_frames=scalar(@frames);
            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] total_frames[$t_frames]");        
            if($t_frames < $frames_ahead)
            {
                &log("content_id[$content_id] skip[$skip] discarding ad_id[$ad_id] - not enough $t_frames < $frames_ahead.");
                #print "\n[$skip] skipping, not enough frames [$t_frames] for this ad_id[$ad_id]";
                next;
            }

            
            my $avg = 0;
            my $total_frames = 0;
            my $tip_frame; my $tail_frame;
            my $tip_frame_i; my $tail_frame_i;

            for(my $i=0;$i<$t_frames;++$i)
            {
                my $ad_chunk=$suspects->{$ad_id}->{$skip}->{frames}->{$frames[$i]}->{ad_chunk};
                my $perc=$suspects->{$ad_id}->{$skip}->{frames}->{$frames[$i]}->{match};
                my $a_diff=$suspects->{$ad_id}->{$skip}->{frames}->{$frames[$i]}->{adiff};
                #$avg += $suspects->{$ad_id}->{$skip}->{frames}->{$frames[$i]}->{match};

                
                my $delta = 0; 
                my $remainder = ($t_frames - $i);
                $remainder = $frames_ahead  if($remainder > $frames_ahead); #was 5

                # total delta between next five successive frames.
                # and check for frames to align with increasing indexed ad_chunks
                my $hits = 0;
                for(my $j=($i+1);$j<($i+1+$remainder);++$j)
                {
                    $delta += ($frames[$j] - $frames[$j-1]);
                    if( $suspects->{$ad_id}->{$skip}->{frames}->{$frames[$j]}->{ad_chunk} > $suspects->{$ad_id}->{$skip}->{frames}->{$frames[$j-1]}->{ad_chunk} )
                    {
                        ++$hits
                    }
                    
                }
                
                if($hits == $remainder && ($delta > 0 && $delta < 200)) # was 125 75
                {
                    if( $remainder >= $frames_ahead && $tip_frame eq undef )
                    {
                        $tip_frame = $frames[$i];
                        $tip_frame_i = $i;
                        &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] setting tip frame[$frames[$i]] tip_frame_i[$tip_frame_i]");
                    }
                    $avg += $suspects->{$ad_id}->{$skip}->{frames}->{$frames[$i]}->{match};
                    ++$total_frames;
                }
                # now we are looking for tail frame
                if($tip_frame ne undef)
                {
                    $avg += $suspects->{$ad_id}->{$skip}->{frames}->{$frames[$i]}->{match};
                    ++$total_frames;

                    if(($frames[$i+1] - $frames[$i]) > 75 || ( ($i+1) == $t_frames) ) # the end
                    {
                        ++$total_frames;
                        $tail_frame = $frames[$i];
                        $tail_frame_i = $i;
                        &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] setting tail frame[$frames[$i]] tail_frame_i[$tail_frame_i]");

                        my $keyframe = nearest(1000,  (($tip_frame + $tail_frame) / 2));

                        #check for other entries with the same ad_id and keyframe
                        my @ss = sort { $a <=> $b} keys %{$candidates->{$ad_id}};

                        if(scalar(@ss))
                        {
                            foreach my $s(@ss)
                            {
                                if($candidates->{$ad_id}->{$s}->{$keyframe})
                                {
                                    if($total_frames > $candidates->{$ad_id}->{$s}->{$keyframe}->{total_frames})
                                    {

                                        $candidates->{$ad_id}->{$skip}->{$keyframe}->{average} = int($avg/$total_frames);
                                        $candidates->{$ad_id}->{$skip}->{$keyframe}->{total_frames} = $total_frames;
                                        if($candidates->{$ad_id}->{$s}->{$keyframe}->{tip_frame} < $tip_frame)
                                        {
                                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] taking [$s]'s tip frame, $candidates->{$ad_id}->{$s}->{$keyframe}->{tip_frame} <=> $tip_frame");
                                            $tip_frame = $candidates->{$ad_id}->{$s}->{$keyframe}->{tip_frame};

                                        }
                                        if($candidates->{$ad_id}->{$s}->{$keyframe}->{tail_frame} > $tail_frame)
                                        {
                                            &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] taking [$s]'s tail frame, $candidates->{$ad_id}->{$s}->{$keyframe}->{tail_frame} <=> $tail_frame");
                                            $tail_frame = $candidates->{$ad_id}->{$s}->{$keyframe}->{tail_frame};

                                        }
                                        $candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_frame} = $tip_frame;
                                        $candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_chunk} = $ad_chunk;
                                        $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame} = $tail_frame;
                                        # delete existing
                                        &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] discarding existing ad, [$s] found a better match.");
                                        
                                        delete $candidates->{$ad_id}->{$s}->{$keyframe};
                                    }
                                }
                            }
                        }
                        else
                        {
                            $candidates->{$ad_id}->{$skip}->{$keyframe}->{average} = int($avg/$total_frames);
                            $candidates->{$ad_id}->{$skip}->{$keyframe}->{total_frames} = $total_frames;
                            $candidates->{$ad_id}->{$skip}->{$keyframe}->{tip_frame} = $tip_frame;
                            $candidates->{$ad_id}->{$skip}->{$keyframe}->{tail_frame} = $tail_frame;
                            $candidates->{$ad_id}->{$skip}->{$keyframe}->{content_id} = $content_id;
                            $candidates->{$ad_id}->{$skip}->{$keyframe}->{cc_data} = $content_id;
                        }   
                    }
                }
            }
                
            if($tip_frame ne undef && $tail_frame ne undef)
            {
                &log("content_id[$content_id] skip[$skip] ad_id[$ad_id] found ad. tip_frame[$tip_frame] tail_frame[$tail_frame]");
                #reset things, there may be another dupe ad in here
                $tip_frame = $tail_frame = undef;
                $total_frames = $avg = 0;
            }
        }
    }
    return $candidates;
}

sub get_bitstring
{
    my ( $bytes ) = @_;
    my @s_mag;
    my $hit;
    my @target =  unpack "(C2048)", $bytes;
    for(my $i=0;$i<scalar(@target);++$i)
    {
        $target[$i] = 1 - ( (($target[$i] - 8192)/8192) ** 2)
    }
    my $fft = Math::FFT->new(\@target);
    my $coeff = $fft->rdft;
    $s_mag[0] = 0;
    for (my $k = 1; $k < @$coeff / 2; $k++) {
        $s_mag[$k] = sqrt( ($coeff->[$k * 2] ** 2) + ($coeff->[$k * 2 + 1] ** 2));
    }
    my @peaks;

    my $b_bitstring;
    my $c = 0;
    my $b_index = 0;
    my $c_bitstring;

    my $len = scalar(@s_mag)/2;
    for(my $i=0;$i<$len;++$i)
    {
        my $done = 0;
        my $hz = $i * 8;# (16384/2048); # sampling rate / fft size
        #print "\n$i: $hz Hz : mag: $s_mag[$i]";# freq: ".$s_mag[$i]*8;

        my $val = $s_mag[$i];
        #print "\n$i: ".int(1000*$val);
        my $h = 0;
        #check left, unrolled and then right
        if( ($i-3 > 0 && ($i+3) < 512) )
        {
            if( $val > $s_mag[$i-1])
            { 
                if( $val > $s_mag[$i-2])
                {
                    if( $val > $s_mag[$i-3])
                    {
                        if( $val > $s_mag[$i+1])
                        {
                            if( $val > $s_mag[$i+2])
                            {
                                if( $val > $s_mag[$i+3])
                                {
                                    ++$h;
                                    $c_bitstring = $c_bitstring."1";
                                    push @peaks, $hz,
                                }

                            }
                        }
                    }
                }
            }
        }
        if(! $h){ $c_bitstring = $c_bitstring."0"; }
    }
    #&log("find_tip_frame: $c_bitstring");
    #&log("find_tip_frame: \n\n\n$c_bitstring\n$tip_frame_freq");
    if(scalar(@peaks))
    {
        return $c_bitstring;
    }
    return undef;
}


sub analyze_chunk
{
    my ($bytes, $skip, $suspects, $flag) = @_;

    my @s_mag;
    my $hit;

    my @target =  unpack "(C2048)", $bytes;
    for(my $i=0;$i<scalar(@target);++$i)
    {
        #$target[$i] = 0.5*(1 - cos( (2*$main::PI*$target[$i]) / 16384) ); # HANN
        $target[$i] = 1 - ( (($target[$i] - 8192)/8192) ** 2)
    }
    my $fft = Math::FFT->new(\@target);
    my $coeff = $fft->rdft;
    $s_mag[0] = 0;#sqrt($coeff->[0]**2);
    for (my $k = 1; $k < @$coeff / 2; $k++) {
        $s_mag[$k] = sqrt( ($coeff->[$k * 2] ** 2) + ($coeff->[$k * 2 + 1] ** 2));

    }
    my @peaks;

    my $b_bitstring;
    my $c = 0;
    #my $c_bitstring;
    my $b_index = 0;
    my $c_bitstring;

    my $len = scalar(@s_mag)/2;
    for(my $i=0;$i<$len;++$i)
    {
        my $done = 0;
        my $hz = $i * 8;# (16384/2048); # sampling rate / fft size
        #print "\n$i: $hz Hz : mag: $s_mag[$i]";# freq: ".$s_mag[$i]*8;

        my $val = $s_mag[$i];
        #print "\n$i: ".int(1000*$val);
        my $h = 0;
        #check left, unrolled and then right
        if( ($i-3 > 0 && ($i+3) < 512) )
        {
            if( $val > $s_mag[$i-1])
            { 
                if( $val > $s_mag[$i-2])
                {
                    if( $val > $s_mag[$i-3])
                    {
                        if( $val > $s_mag[$i+1])
                        {
                            if( $val > $s_mag[$i+2])
                            {
                                if( $val > $s_mag[$i+3])
                                {
                                    ++$h;
                                    $c_bitstring = $c_bitstring."1";
                                    push @peaks, $hz,
                                }

                            }
                        }
                    }
                }
            }
        }
        if(! $h){ $c_bitstring = $c_bitstring."0"; }
    }

    #print "\npeaks [".scalar(@peaks)."]: ".join(",", @peaks);
    #print "\nchunk_bitstring: ".$c_bitstring;
    #print "\nsize ".scalar(@c_bitstrings);
    # COMPARE TO CHUNKS IN MEMORY
    #my $i=0;
    #foreach my $c_bstring (@c_bitstrings)
    #{
    #    print "\nc_bstring [$i]: $c_bstring";
    #    ++$i;
    #}

    #if(scalar(@peaks))
    if(length($c_bitstring) == 512)
    {
        my @bucket;
        for(my $i=0;$i<512;$i+=64)
        {
            my $bs = oct("0b".substr($c_bitstring, $i, 32));
            push @bucket, $bs;

        }
        
        #$buckets->{"bucket_$i"}->{$ref->{"bucket_$i"}}->{$ref->{id}} = 1;
        
        my $hits = 0;
        my $b_string;
        my $chunk_hash;
        for(my $i=0;$i<=7;$i+=1)
        {
            #my @chunk_ids = scalar(keys %{$buckets->{"bucket_$i"}->{$bucket[$i]}});
            #&log("KO ".." <=> ".$bucket[$i]);
            if(exists $buckets->{"bucket_$i"}->{$bucket[$i]})
            {
                foreach my $chunk (@{$buckets->{"bucket_$i"}->{$bucket[$i]}})
                {
                    $chunk_hash->{$chunk}++;
                    #&log("checking $chunk")
                }
                #push @chunks, $buckets->{"bucket_$i"}->{$bucket[$i]}
                #&log("$main::frame KO HIT bucket_$i $bucket[$i]");# bucket: $bucket[$i] $chunk_ids[0] ".scalar(@chunk_ids));
                #$b_string .= "$bucket[$i] ";
                #++$hits;
            }
        }

        foreach my $chunk (keys %{$chunk_hash})
        {
            # might sort to start with best first
            if($chunk_hash->{$chunk} >= 1)
            {
                my $matches = c_cmp($c_bitstring, $freqs->{$chunk});
                if($matches >= 442)
                {
                    my $perc = int(100*($matches)/512);
                    my $ad_id = $main::ad_chunks->{$chunk}->{ad_id};
                    $suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{match} = $perc;
                    $suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{ad_chunk} = $chunk;
                    #$suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{bitstring} = $c_bitstring;
                    $suspects->{$ad_id}->{$skip}->{total_frames}++;                    
                    &log("[$skip] [$main::frame] hit! $res");
                    return $res;
                        
                }
                #return $res;
            }
        }
        return 255;
        
        #&log("hits: $hits");
        if($hits >=5)
        {
            #&log("$main::frame hits: $hits\n$b_string");
            return 0;
        }
        return 255;




















        
    #    exit;
        if(0){
        my $chunk_ids=$buckets->{"bucket_$i"}->{$bucket[$i]};
        if($chunk_ids)
        {
            foreach my $chunk_id (keys %{$chunk_ids})
            {
                #&log("looing at $chunk_id");
                # for this chunkid how many hits do we get
                my $hits = 0;
                for(my $j=$i;$j<=7;$j+=1)
                {
                    #&log("bucket_$j $bucket[$j]");
                    if($chunks->{$chunk_id}->{"bucket_$j"}->{$bucket[$j]} == 1)
                    {
                        ++$hits;
                    }
                }
                if($hits > 4)
                {
                    my $ad_id = $main::ad_chunks->{$chunk_id}->{ad_id};
                    &log("[$skip] $main::frame ad_id[$ad_id] got $hits for chunk_id:$chunk_id");
                    $f_chunk_id=$chunk_id;
                    #goto done;
                }
                #return if($hits == 8);
            }
        } #else { &log("no chunks") }
        #return 0 if($i>4 && $hits < 2);
        }










        
        #calc bucket
        my $bucket =oct("0b".substr($c_bitstring, 0, 16)); # 16
        for(my $i=16;$i<512;$i+=64)
        {
            my $tmp =oct("0b".substr($c_bitstring, $i, 16)); # 16
            #print "\n$i $tmp";
        }
        
        #print "\nlooking in bucket $bucket";
        # then look in bucket for match
        my $ref = $buckets->{$bucket};
        if( $ref  )
        {
            my @chunk_ids = @{$ref->{chunk_ids}}; # optimize these
            my @freqs = @{$ref->{freqs}};
            my $ids = scalar(@chunk_ids);
            for(my $i=0;$i<$ids;++$i)
            {
                #my $ad_id = $main::ad_chunks->{unshift @chunk_ids}->{ad_id};
                my $ad_id = $main::ad_chunks->{$chunk_ids[$i]}->{ad_id};
                my $t_diff = 0;
                my $a_diff = 0;
                #my $matches = ($c_bitstring ^ $freqs[$i]) =~ tr/\0//;
                
                my $matches = c_cmp($c_bitstring, $freqs[$i]);
                #print "\n$matches";
                $t_diff = 512-$matches;
                if($t_diff == 0)
                {
                    print "*";
                    #++$matches;
                    my $perc = 100;
                    $hit = $perc;
                    #print "\n\t*** ad_chunk of ad_id: ".$ad_id." ad_chunk: $chunk_ids[$i] matches 100%";
                    #print "\n\t*** ad_id [$ad_id] frame[$main::frame] matches ad_chunk[$chunk_ids[$i]] matches 100%";
                    $suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{match} = $perc;
                    $suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{ad_chunk} = $chunk_ids[$i];
                    $suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{adiff} = $t_diff;
                    $suspects->{$ad_id}->{$skip}->{total_frames}++;
                    #$suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{match} = 100;
                    #$suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{ad_chunk} = $ad_chunk;
                    #$suspects->{$ad_id}->{$skip}->{total_frames}++;
                    goto done;
                }
                else
                {
                    if($t_diff <= 70) #was 60 as of Sep 8,  100 50, 70
                    {
                        my $perc = int(100*(512-$t_diff)/512);
                        $hit = $perc if($perc > $hit);
                        print ".";
                        #print "\n\t*** [$skip:$flag] ad_id [$ad_id] frame[$main::frame] matches ad_chunk[$chunk_ids[$i]] matches $perc%" if($flag);
                        $suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{match} = $perc;
                        $suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{ad_chunk} = $chunk_ids[$i];
                        $suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{adiff} = $t_diff;
                        $suspects->{$ad_id}->{$skip}->{frames}->{$main::frame}->{bitstring} = $c_bitstring;
                        $suspects->{$ad_id}->{$skip}->{total_frames}++;
                        #if($main::frame > 7100 && $main::frame < 7300)
                        #{
                        #    &log("HERE [$skip] perc: $perc $main::frame!")
                        #}
                    }
                }
            }
          done:
        }
    }
    return $hit;
}


sub log
{
    my ($msg) = @_;

    print LFH "\n".localtime(time)." : $msg";
    print "\n".localtime(time)." : $msg";
    flush(*LFH);
}
sub flush {
   my $h = select($_[0]); my $af=$|; $|=1; $|=$af; select($h);
}


__END__
__C__
int add(int x, int y) {
  return x + y;
}
 
int subtract(int x, int y) {
  return x - y;
}

char _bytes[2049];
char *c_substr(char *src, int offset, int length)
{
    strncpy(_bytes, src+offset, length);
    _bytes[2048]=0;
    return(_bytes);
}
int c_cmp(char *a1, char *b1)
{
   int diff = 512;
   int i;
   //for(i=0;i<512;++i) // 70-1
   for(i=0;i<512;++i) // 70-1
   {
      if( *(a1+i) != *(b1+i))
          --diff;
      if(diff < 442 ){ return 255; } // 60=452 70=442 80=432
   }
   return(diff);
}

