package backpack;
use warnings;
use strict;

sub new {
    my $class = shift;

    my $self = {
        color => 'blue',
        items => [],
    };
    bless($self, $class);
    return($self);
}

sub color {
    my $self = shift;
    return $self->{color};
}

sub name {'backpack'}

sub getItem {
     my $self = shift;
     my $i = shift;
     foreach my $item (@{$self->{items}})
     {
         return $item if($item->name() eq $i);
     }
     return undef;
}

sub add_items {
    my $self = shift;
    my (@items) = @_;

    push(@{$self->{items}}, @items);
    return @items;
}
1;
