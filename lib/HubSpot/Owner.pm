package HubSpot::Owner;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;

use Class::Tiny qw(
    archived 
    createdAt 
    email 
    firstName 
    lastName 
    updatedAt 
    userId
    name
);
use parent 'HubSpot::JSONBackedObject';

sub BUILD {
    my $self = shift;
    $self->{name} = join(' ', $self->firstName, $self->lastName);
}

1;
