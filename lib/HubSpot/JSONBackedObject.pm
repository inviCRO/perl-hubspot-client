package HubSpot::JSONBackedObject;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;

# Make us a class
use Class::Tiny qw(),
{
	json => undef,
};

sub BUILD
{
	my ($self, $args) = @_;
	
	if(defined($args->{'json'}))
	{
		# Not actually JSON but a perl object derived from the JSON response
		$self->json($args->{'json'});
	}
}
	
1;
