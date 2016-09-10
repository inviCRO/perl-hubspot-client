package HubSpot::Deal;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;

# Make us a class
use Class::Tiny qw(json),
{
		# Default variables in here
};

# Global variables
#my $json = undef;

sub BUILD
{
	my ($self, $args) = @_;
	
	if(defined($args->{'json'}))
	{
		# Not actually JSON but a perl object derived from the JSON response
		$self->json($args->{'json'});
	}
	else
	{
		die "Must specify 'json' argument to HubSpot::Deal::new()";
	}
}

sub name
{
	my $self = shift;
	
#	print STDERR Data::Dumper->Dump([$json->{'properties'}]);
	
	return $self->json->{'properties'}->{'dealname'}->{'value'};
}

sub id
{
	my $self = shift;
	
	return $self->json->{'dealId'};
}

1;
