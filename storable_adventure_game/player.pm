package player;
use mobile;
use place;
use strict;
our @ISA = qw(mobile, place, places);

package player;

sub new {
    my ($class) = @_;
    my $self = $class->SUPER::new( );
    # Add few more attributes
    $self->{_firstName} = $_[1];
    $self->{_lastName} = $_[2];
    $self->{_x} = $_[3];
    $self->{_y} = $_[4];
    $self->{_z} = $_[5];
    $self->{_id} = $_[6];
    $self->{_xyz} = "$_[3],$_[4],$_[5]";
    $self->{_status} = "";
    $self->{_hits} = 0;
    $self->{_place} = undef;
    $self->{_backpack} = undef,
    bless $self, $class;
    return $self;
}

sub setBackpack { my ($self, $a) = @_; $self->{_backpack} = $a; };
sub getBackpack { my ($self) = @_; return $self->{_backpack}; };

sub incHits { my ($self) = @_; return ++$self->{_hits}; }

sub firstName { my ($self) = @_; return $self->{_firstName}; }
sub lastName { my ($self) = @_; return $self->{_lastName}; }


sub getStatus { my ($self) = @_; return $self->{_status};}
sub setStatus { my ($self, $status) = @_; $self->{_status} = $status;}

sub getMessage { my ($self) = @_; return $self->{_message};}
sub setMessage { my ($self, $message) = @_; $self->{_message} = $message;}

sub getXYZ
{
    my ($self) = @_;
    return $self->{_xyz};
}
sub setXYZ { my ($self, $p) = @_; $self->{_xyz} = $p; }

sub goInside
{
    my ($self) = @_;
    my $place = $main::places->findPlace( $self->{_xyz});
    if($place->getEnterable())
    {
        $self->{_inside} = 1;
    }
}
sub goOutside
{
    my ($self, $places) = @_;
    my $place = $places->findPlace( $self->{_xyz});
    if($place->getEnterable())
    {
        $self->{_inside} = 0;
    }
}

sub addItemPlace
{
    my ($self, $places, $item) = @_;
    my $place = $places->findPlace( $self->{_xyz});
    $place->addItem( $item );
}

sub getPlace
{
    my ($self) = @_;
    if(! $self->{_place})
    {
       my $p = $main::places->findPlace( $self->{_xyz} );
       if($p)
       {
           $self->{_place} = $p;
       }
    }
    return $self->{_place};
}

sub setPlace
{
    my ($self, $a) = @_;
    my $place = $main::places->findPlace( $a );
    if($place)
    {
        $self->{_place} = $place;
        $self->{_xyz} = $a;
        $place->setWhosHere( \$self );
    }
}

sub getPlaceDescription
{
    my ($self) = @_;
    my $place = $self->getPlace();
    my $name = $main::places->getPlaceName( $place );
    my $o = "the";
    $o = "your " if( $self->{_id} == $self->getPlace->getOwnerId );
    if($place->getEnterable())
    {
        $self->{_inside} ? return "inside $o $name": return "outside $o $name";
    }
    return "at the $name";



    my $io = "inside";
    $io = "outside";

    if($self->{_id} == $main::places->getOwnerId( $place ))
    {
        my $io = "inside";
        $io = "outside" if($self->{_outside});
        return "$io the ".$place->{_name};
    }
    else
    {
        return $main::places->getName( );
    }
}

sub getart
{
    my ($self) = @_;
    $self->{_art_1} = <<XXX;
                                                ( 
                                               )          /\
                                               _(_       /%%\
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
    $self->{_art_2} = <<XXX;
                                               (
                                                )         /\
                                               _(_       /%%\
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
    my $h = int( rand(2) ) + 1;
    return $self->{"_art_$h"};
}
1;
