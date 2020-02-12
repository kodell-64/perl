package character;

sub new
{
    my $class = shift;
    my $self = {
        _id => 0,
        _name => shift,
        _x => 1000000,
        _y => 1000000,
        _journal => [],
        _current_area => undef,
    };

    #push @{$self->{_buildings}}, new building("Hansel's Mercantile");
    bless $self, $class;
    return $self;
}

sub run
{
    my ($self, $areas) = @_;

    # moving?
    $self->{_x} += $self->{_x_direction};
    $self->{_y} += $self->{_y_direction};

    &main::display("character", "reset");
    my @areas = @{$areas->get_areas()};
    my $c_area;
    my @distances;
    #open(FH, ">>out.log");
    foreach my $area (@areas)
    {
        #print FH "\nchecking $area->{_name}";
        my $dist = $area->is_within($self->{_x}, $self->{_y});
        if($dist >= 0)
        {

            #print FH "\nchecking $self->{_x}, $self->{_y} $area->{_tx} $area->{_ty} $area->{_bx} $area->{_by}";
            push @distances, "$area->{_name} $dist";

            $c_area .= $area->{_name}. ", ";
        }
    }
    close FH;
    if(scalar(@distances))
    {
        &main::display("character", "dists: ".join(",", @distances));
    }
    else { &main::display("character", "no dists") }
    chop $c_area;chop $c_area;
    my $dir;
    $dir = "east" if($self->{_x_direction} == +1);
    $dir = "west" if($self->{_x_direction} == -1);
    $dir = "north$dir" if($self->{_y_direction} == -1);
    $dir = "south$dir" if($self->{_y_direction} == +1);

    my $movement = "                             ";
    if($dir)
    {
        $movement = "and is walking $dir.         ";
    }

    &main::display("character", "character: $self->{_name} [$self->{_x}] [$self->{_y}] is in $c_area $movement");
    &main::display("character", "draw");
}

1;
