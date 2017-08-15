package HubSpot::Owner;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;

# Make us a class
use subs qw(firstName lastName email);
use Class::Tiny qw(firstName lastName email),
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
	
	return $self->json->{'ownerId'};
}

sub firstName
{
	my $self = shift;
	
	return $self->json->{'firstName'};
}
	
sub lastName
{
	my $self = shift;
	
	return $self->json->{'lastName'};
}
	
sub email
{
	my $self = shift;
	
	return $self->json->{'email'};
}
	
1;
