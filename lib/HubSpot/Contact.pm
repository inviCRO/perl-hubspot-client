package HubSpot::Contact;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;

# Make us a class
use subs qw(id);
use Class::Tiny qw(id),
{
		# Default variables in here
};
use parent 'HubSpot::JSONBackedObject';

sub name
{
	my $self = shift;
	
	return $self->firstName." ".$self->lastName;
}

sub id
{
	my $self = shift;
	
	return $self->json->{'vid'};
}

1;
