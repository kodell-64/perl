use warnings;
use strict;

package item;
sub new {
    my $id = 1000;
    my $class = shift;
    my $self = {
        _weight => 0.25,
        _uses => int(rand(10)+90),
        _id => ++$id,
    };
    bless $self, $class;
    return $self;
}

sub getUses { my $self = shift; return $self->{_uses} }
sub weight { my $self = shift; return $self->{_weight} }
1;
