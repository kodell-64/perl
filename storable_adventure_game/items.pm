use warnings;
use strict;
use item;

package bed;
our @ISA = qw(item);
sub new { my ($class) = @_; my $self = $class->SUPER::new( ); 
          $self->{_weight} = 21; $self->{_uses} = "unlimited"; bless $self, $class; return $self; }
sub name {'bed'}

package candle;
our @ISA = qw(item);
sub name {'candle'}

package axe;
our @ISA = qw(item);
sub new { my ($class) = @_; my $self = $class->SUPER::new( ); 
          $self->{_weight} = 3; bless $self, $class; return $self; }
sub name {'axe'}
1;
