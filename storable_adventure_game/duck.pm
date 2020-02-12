package duck;
sub new
{
    my $class = shift;
    my $self = {
        _id => shift,
        _type => "duck",
    };
    bless $self, $class;
    return $self;
}

sub run
{
    my ($self) = @_;
    print "\n\t$self->{_type}:\#$self->{_id} running";

}
1;
