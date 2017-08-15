package HubSpot::Engagement;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;
use Switch;

# Make us a class
use subs qw(type);
use Class::Tiny qw(type content),
{
		# Default variables in here
};
use parent 'HubSpot::JSONBackedObject';
	
use constant {
		NOTE => 'NOTE',
		EMAIL => 'EMAIL',
		MEETING => 'MEETING',
		CALL => 'CALL',
		TASK => 'TASK',
};
	
sub BUILD
{
	my ($self, $args) = @_;

	if(defined($args->{'type'}))
	{
		$self->type($args->{'type'});
	}
	else
	{
		die("No engagement type specified");
	}
		
#	{
#    "engagement": {
#        "active": true,
#        "ownerId": 1,
#        "type": "NOTE",
#        "timestamp": 1409172644778
#    },
#    "associations": {
#        "contactIds": [2],
#        "companyIds": [ ],
#        "dealIds": [ ],
#        "ownerIds": [ ]
#    },
#    "metadata": {
#        "body": "note body"
#    }
}
	
sub type
{
	my $self = shift;
	my $type = shift;
	
	if(defined($type))
	{	# Check the provided type is one of the constants
		switch($type)
		{
			case NOTE		{ $self->{type} = NOTE }
			case EMAIL		{ $self->{type} = EMAIL }
			case MEETING	{ $self->{type} = MEETING }
			case CALL		{ $self->{type} = CALL }
			case TASK		{ $self->{type} = TASK }
			else			{ die("Unknown engagement type '$type'. Must be one of HubSpot::Engagement->NOTE, ->EMAIL, ->MEETING, ->CALL or ->TASK") }
#			else			{ die }
		}
	}
	else
	{
		return $self->{type};
	}
}
	
1;
