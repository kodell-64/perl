package mobile;
sub new
{
    my $class = shift;
    my $self = {
        $self->{_currentPlace} = undef,
    };
    bless $self, $class;
    return $self;
}


1;
