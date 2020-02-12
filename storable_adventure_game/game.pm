package game;

sub new
{
    my $class = shift;
    my $self = {
        _id => 0,
        _list => [],
    };
    bless $self, $class;
    return $self;
}

sub run
{
    my ($self) = @_;
    foreach my $g (@{$self->{_list}})
    {
        $g->run();
    }
}

sub dump
{
    my ($self) = @_;
    foreach my $g (@{$self->{_list}})
    {
        print "\ngame: type: $g->{_type} count: $g->{_count}";
    }
}
sub add
{
    my ($self, $type, $count, $range_max, $range_home, $location) = @_;
    push @{$self->{_list}}, $type->new( ++$self->{_id}, $count, $range_max,
        $range_home, $location);
    #if($type eq "elk_herd")
    #{
    #    print "\ncreating new game object::elk_herd";
    #    push @{$self->{_list}}, new elk_herd( ++$self->{_id}, $count );
    #}
}

package elk_herd;
sub new
{
    my $class = shift;
    my $self = {
        _type => "elk_herd",
        _id => shift,
        _count => shift,
        _range_max => shift,
        _range_home => shift,
        _location => shift,
        _elk => [],
        _win_topx => 30,
        _win_topy => 150,
        _win_content => [],
    };
    for(my $i=1;$i<=$self->{_count};++$i)
    {
        push @{$self->{_elk}}, new elk( $i, 
                                        $self->{_range_max}, 
                                        $self->{_range_home},
                                        $self->{_win_content},
            );
    }
    bless $self, $class;
    return $self;
}

sub run
{
    my ($self) = @_;
    #print "\n$self->{_type}:\#$self->{_id} running";
    #$main::winx = 1;
    #&main::display("game", "$self->{_location}");
    #&main::refresh();
    #&main::display("game", "reset");
    for(my $i=0;$i<$self->{_count};++$i)
    {
        $self->{_elk}[$i]->run();
    }
    #&main::display("game", "draw");
    my $x = $self->{_win_topx};
    my $y = $self->{_win_topy};
    foreach my $line (@{$self->{_win_content}})
    {
        &main::addstr($x++, $y, $line);
    }
    refresh;
    $self->{_win_content} = ();
}

package mobile;
sub new
{
    my $class = shift;
    my $self = {
        _id => shift,
        _type => shift,
        _range_max => shift,
        _range_home => shift,
        _win_content => shift,
        _seeks_water => undef,
        _action_state => undef,
        _action_time => undef,
        _x => undef,
        _y => undef,
        _sex => undef,
    };
    bless $self, $class;
    return $self;
}
sub dump
{
}


package elk;
our @ISA = qw ( mobile );

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new( shift, "elk", shift, shift, shift );
    # add others here
    $self->{_actions} = { "10" => "bedded down", "100" => "grazing" };
    $self->{_graze_path} = undef;
    $self->{_last_roll} = undef;
    my ($x1, $y1, $x2, $y2) = split(/,/, $self->{_range_max});
    $self->{_x} = $x1+int(rand($x2-$x1));
    $self->{_y} = $y1+int(rand($y2-$y1));
    $self->{_sex} = (rand(100) >= 90) ? "bull" : "cow";
    $self->{_sex} = (rand(100) >= 90) ? "calf" : $self->{_sex};
    $self->{_action_state} = "idle";
    bless $self, $class;
    return $self;
}

sub run
{
    my ($self) = @_;
    $self->action();
    push @{$self->{_win_content}}, "$self->{_type}:\#$self->{_id} : [$self->{_sex}] : [$self->{_x},$self->{_y}] : [$self->{_action_state}] [$self->{_last_roll}] [$self->{_graze_path}]";


    #&main::display("game", "$self->{_type}:\#$self->{_id} : [$self->{_sex}] : [$self->{_x},$self->{_y}] : [$self->{_action_state}] [$self->{_last_roll}] [$self->{_graze_path}]");
    #&main::addstr($main::winx++,80, "$self->{_type}:\#$self->{_id} : [$self->{_sex}] : [$self->{_x},$self->{_y}] : [$self->{_action_state}] [$self->{_last_roll}] [$self->{_graze_path}]");
    #print "\n\t$self->{_type}:\#$self->{_id} : [$self->{_x},$self->{_y}] : [$self->{_action_state}]";
    #&main::refresh();
}

sub action
{    
    my ($self) = @_;

    if( $self->{_action_time} < time )
    {
        $self->{_last_roll} = int(rand(100));
        foreach my $prob (sort keys %{$self->{_actions}})
        {
            if($self->{_last_roll} <= $prob)
            {
                $self->{_action_state} = $self->{_actions}->{$prob};last;
            }
        }
        $self->{_action_time} = int(rand(60)) + time;
    }
    if($self->{_action_state} eq "idle")
    {
        if( ! $self->{_action_time} )
        {
            $self->{_action_time} = int(rand(60)) + time;
        }
    }
    if($self->{_action_state} eq "grazing")
    {
        $self->{_graze_path} = ($self->{_x}+10).",".$self->{_y} if(! $self->{_graze_path});
        if( rand(100) <= 10)
        {
            $self->{_x} += (rand(100) > 50) ? 1 : 0;
        }
        # clear it when we reach it
        $self->{_graze_path} = undef if( "$self->{_x},$self->{_y}" eq $self->{_graze_path});
    }
}

package duck_flock;
sub new
{
    my $class = shift;
    my $self = {
        _type => "duck_flock",
        _id => shift,
        _count => shift,
        _ducks => [],
    };
    for(my $i=1;$i<=$self->{_count};++$i)
    {
        push @{$self->{_ducks}}, new duck( $i );
    }
    bless $self, $class;
    return $self;
}

sub run
{
    my ($self) = @_;
    print "\n$self->{_type}:\#$self->{_id} running";
    for(my $i=0;$i<$self->{_count};++$i)
    {
        $self->{_ducks}[$i]->run();
    }
}

package duck;
our @ISA = qw ( mobile );
sub new
{
    my $class = shift;
    my $self = $class->SUPER::new( shift, "duck" );
    $self->{_seeks_water} = true;
    bless $self, $class;
    return $self;
}

sub run
{
    my ($self) = @_;
    print "\n\t$self->{_type}:\#$self->{_id}:";

}



1;
