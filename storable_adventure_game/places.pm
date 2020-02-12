package places;
use strict;

#########################################################################33
# package place
#########################################################################33
package place;
sub new
{
    my $class = shift;
    my $self = {
        _type => shift,
        _name => shift,
        _firstName => shift,
        _lastName => shift,
        _ownerId => shift,
        _x => shift,
        _y  => shift,
        _z  => shift,
        _enterable => shift,
        _whosHere => [],
        _items => [],
    };
    $self->{_xyz} = "$self->{_x},$self->{_y},$self->{_z}";
    bless $self, $class;
    return $self;
}

#########################################################################33
# accessors
#########################################################################33
sub getEnterable { my $self = shift; return $self->{_enterable} }
sub getWhosHere
{
   my ($self) = @_;
   $self->{_whosHere};
}

sub setWhosHere
{
   my ($self, $p) = @_;
   push @{$self->{_whosHere}}, $p;
}
sub getName { 
    my $self = shift; 
    my $name;
    $name .= $self->{_firstName}." " if(defined $self->{_firstName});
    $name .= $self->{_lastName}."'s " if(defined $self->{_lastName});
    $name .= $self->{_name} if(defined $self->{_name});
}
sub getOwnerId { my $self = shift; return $self->{_ownerId} }

#########################################################################33
# mutators
#########################################################################33
sub addItem {
    my $self = shift;
    my (@items) = @_;

    push(@{$self->{_items}}, @items);
    return @items;
}

#########################################################################33
# package places
#########################################################################33

package places;
sub new
{
    my $class = shift;
    my $self = {
    };
    bless $self, $class;
    return $self;
}

#########################################################################33
# accessors
#########################################################################33

sub findPlace
{
    my ($self, $xyz) = @_;
    foreach my $p (@{$self->{_places}})
    {
        return $p if($p->{_xyz} == $xyz);
    }
    return undef;
}
sub getPlaceName { my ($self, $place) = @_; return $place->{_name} }
sub getOwnerId { my ($self, $place) = @_; return $place->{_ownerId} }
sub getNameByXYZ
{
    my ($self, $xyz) = @_;
    my $name = "an unknown location";
    if(defined $self->{$xyz})
    {
        $name = $self->{$xyz}->{_firstName};
        $name .= $self->{$xyz}->{_lastName};
        $name .= "'s".$self->{$xyz}->{_name};
    }
    return $name;
}

#########################################################################33
# mutators
#########################################################################33
sub addPlace
{
    my ($self, $p) = @_;
    #my $xyz = "$_[5],$_[6],$_[7]";
    #my $p = new place( $_[1], $_[2], $_[3], $_[4], $xyz, $_[5], $_[6], $_[7], $_[8] );
    push @{$self->{_places}}, $p;
}
1;
