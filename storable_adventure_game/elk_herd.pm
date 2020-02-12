package elk_herd;
use elk;
sub new
{
    my $class = shift;
    my $self = {
        _type => "elk_herd",
        _id => shift,
        _count => shift,
        _elk => [],
    };
    for(my $i=1;$i<=$self->{_count};++$i)
    {
        push @{$self->{_elk}}, new elk( $i );
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
        $self->{_elk}[$i]->run();
    }

}
1;
