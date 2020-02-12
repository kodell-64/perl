package building;
use place;
use strict;
our @ISA = qw(place);

sub new
{
    my ($class) = @_;

    my $self = $class->SUPER::new( $_[1], $_[2], $_[3] );
    $self->{_id}   = undef;
    $self->{_title} = undef;
    $self->{_art} =       '
                           (   )
                          (    )
                           (    )
                          (    )
                            )  )
                           (  (                  /\
                            (_)                 /  \  /\
                    ________[_]________      /\/    \/  \
           /\      /\        ______    \    /   /\/\  /\/\
          /  \    //_\       \    /\    \  /\/\/    \/    \
   /\    / /\/\  //___\       \__/  \    \/
  /  \  /\/    \//_____\       \ |[]|     \
 /\/\/\/       //_______\       \|__|      \
/      \      /XXXXXXXXXX\                  \
        \    /_I_II  I__I_\__________________\
               I_I|  I__I_____[]_|_[]_____I
               I_II  I__I_____[]_|_[]_____I
               I II__I  I     XXXXXXX     I
            ~~~~~"   "~~~~~~~~~~~~~~~~~~~~~~~~';

    $self->{_art} = <<XXX;
                                               (
                                                )        /\
                                               (__      /%%\
                                              |_I_|     /%%\
                   ___________________________|I_I|____/%%%%\/\
                  /\'.__.'.__.'.__.'.___.'.__.'.__.'.__\%%%%/%%\
                 /%%\_.'.__.'.__.'.__.'.'.__.'.'.__.'._.\%%/%%%%\
                /%%%%\.__.'.__.'.__.'.__.'.__.''.__.'.__.\%/%%%%\   
                /%%%%\_.'.__.'.__.'.__.'.__.'.__.'.__.'.__\%%%%%%\              
               /%%%%%%\____________________________________\%%%%%%\
              /%%%%%%%%\]== _ _ _ ============______======]%%%%%%%\
              /%%%%%%%/\]==|_|_|_|============|////|======]%%%%%%%%\
             /%%%%%%%/%%\==|_|_|_|============|////|======]%%%%%%%%\
            /%%%%%%%/%%%%\====================|;///|======]%%%%%%%%%\
            /%%%%%%%/%%%%\====================|////|======]^^^^^^^^^^
           /%%%%%%%/%%%%%%\===================|////|======]  _ - _ -
           /%%%%%%%/%%%%%%\"""""""""""""""""""'===='"""""""
           ^^^^^^^/%%%%%%%%\   _ -   _ -              _-
                  ^^^^^^^^^^               
XXX

    bless $self, $class;
    return $self;
}
1;
