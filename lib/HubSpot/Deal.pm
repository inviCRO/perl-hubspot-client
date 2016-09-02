package HubSpot::Deal;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Make us a class
use subs 'name';
use Class::Tiny qw(_json name),
{
		# Default variables in here
};

# Global variables
my $json = undef;

sub BUILD
{
	my ($self, $args) = @_;
	
	if(defined($args->{'json'}))
	{
		# Not actually JSON but a perl object derived from the JSON response
		$self->_json($args->{'json'});
	}
	else
	{
		die "Must specify 'json' argument to HubSpot::Deal::new()";
	}
}

sub name
{
	my $self = shift;
	
	
	return $self->_json->{'properties'}->{'dealName'}->{'value'};
}

1;
