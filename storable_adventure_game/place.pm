package place;
sub new
{
    my $class = shift;
    my $self = {
        _name => shift,
        _x => shift,
        _y => shift,
        _z => shift,
    };
    bless $self, $class;
    return $self;
}
sub getXYZ
{
    my ($self) = @_;
    return "$self->{_x},$self->{_y},$self->{_z}";
}
1;
