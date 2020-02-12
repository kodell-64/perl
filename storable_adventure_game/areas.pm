package areas;
sub new
{
    my $class = shift;
    my $self = {
        _areas => [],
    };
    bless $self, $class;
    return $self;
}

sub add_area
{
    my ($self) = shift;
    my $area = area->new(shift,shift,shift,shift,shift,shift);
    push @{$self->{_areas}}, $area;
    return $area;
}

sub get_areas
{
    my ($self) = shift;
    return $self->{_areas};
}

sub run
{
    my ($self) = shift;
    &main::display("areas", "reset");
    &main::display("areas", "------------- areas --------");
    foreach my $area (@{$self->{_areas}})
    {
        my $type = $area->{_type};
        &main::display("areas", "$type : $area->{_name} [$area->{_x}] [$area->{_y}] [$area->{_tx},$area->{_ty} $area->{_bx},$area->{_by}]");
    }
    &main::display("areas", "draw");
}

package area;
use building;
sub new
{
    my $class = shift;
    my $self = {
        _id => 0,
        _type => shift,
        _name => shift,
        _x => shift,
        _y => shift,
        _dimx => shift,
        _dimy => shift,
        _tx => undef,
        _ty => undef,
        _bx => undef,
        _by => undef,
        _buildings => [],
    };
    # calc tx,ty,bx,by
    $self->{_tx} = $self->{_x} - int(($self->{_dimx} / 2));
    $self->{_ty} = $self->{_y} - int(($self->{_dimy} / 2));
    $self->{_bx} = $self->{_x} + int(($self->{_dimx} / 2));
    $self->{_by} = $self->{_y} + int(($self->{_dimy} / 2));

    bless $self, $class;
    return $self;
}

sub add_building
{
    my ($self) = shift;
    push @{$self->{_buildings}}, new building(shift, shift, shift, shift, shift);#"Hansel's Mercantile", 100000, 100000, 7, 7);
}
sub run
{
    my ($self) = @_;
    &main::display("area", "reset");
    &main::display("area", "$self->{_name} : [$self->{_tx},$self->{_ty} $self->{_bx},$self->{_by}] [$self->{_x}] [$self->{_y}]");
    foreach my $b (@{$self->{_buildings}})
    {
        &main::display("area", "building : $b->{_name} [$b->{_x}] [$b->{_y}] [$b->{_tx},$b->{_ty} $b->{_bx},$b->{_by}] ");
    }
    &main::display("area", "draw");
}

sub is_within
{
    my ($self, $x, $y) = @_;
    #open(FH, ">>out.log");
    #print FH "\n$self->{_name}: x=$x y=$y $self->{_tx},$self->{_ty} $self->{_bx},$self->{_by}";


    if($x >= $self->{_tx} && $x <= $self->{_bx}
       && $y >= $self->{_ty} && $y <= $self->{_by})
    {
        # return distance from center point of area
        my $a = abs( ($x-$self->{_x}) ) ** 2;
        my $b = abs( ($y-$self->{_y}) ) ** 2;
        my $c = ($a + $b)**0.5;
        #print FH " a=$a b=$b c=$c";
        return int($c);
    }
    return -1;
}

package building;

sub new
{
    my $class = shift;
    my $self = {
        _id => 0,
        _name => shift,
        _x => shift,
        _y => shift,
        _dimx => shift,
        _dimy => shift,
        _tx => undef,
        _ty => undef,
        _bx => undef,
        _by => undef,
    };
    # calc building tx,ty,bx,by
    $self->{_tx} = $self->{_x} - int(($self->{_dimx} / 2));
    $self->{_ty} = $self->{_y} - int(($self->{_dimy} / 2));
    $self->{_bx} = $self->{_x} + int(($self->{_dimx} / 2));
    $self->{_by} = $self->{_y} + int(($self->{_dimy} / 2));

    bless $self, $class;
    return $self;
}

sub is_within
{
    my ($self, $x, $y) = @_;
    return 1 if($x >= $self->{_tx} && $x <= $self->{_bx}
                && $y >= $self->{_ty} && $y <= $self->{_by});
    return 0;
}
    
1;
