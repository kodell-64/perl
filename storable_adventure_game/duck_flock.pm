package duck_flock;
use duck;
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
1;
