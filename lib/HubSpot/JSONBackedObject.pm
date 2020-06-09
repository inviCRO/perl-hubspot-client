package HubSpot::JSONBackedObject;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;
use Time::Piece;

# Classes we need
use Data::Dumper;

# Make us a class
use Class::Tiny qw(properties),
{
	json => undef,
};

sub BUILD
{
	my ($self, $args) = @_;
    warn "BUILD: JSONBackedObject ($self)\n";
	
	if(defined($args->{'json'}))
	{
		# Not actually JSON but a perl object derived from the JSON response
		$self->json($args->{'json'});
	}
	
	if(defined($self->json->{'properties'}))
	{	# If this object has a properties key (which probably most of them will)
		# pull it out as a hash that is a little easier to access
		$self->properties({});
		foreach my $property (keys %{$self->json->{'properties'}})
		{
			$self->properties->{$property} = $self->json->{'properties'}->{$property}->{'value'} if length($self->json->{'properties'}->{$property}->{'value'}) > 0;
		}
	}

    for my $attr ( Class::Tiny->get_all_attributes_for(ref $self) ) {
        next if defined $self->{ $attr };
        $self->{ $attr } = $self->{properties}{ $attr };
        if ($attr =~ /date$/) {
            $self->{ $attr } = Time::Piece->new( $self->{ $attr } );
        }
    }
}

sub getProperty
{
	my $self = shift;
	my $key = shift;

	return $self->properties->{$key};
}
	
1;
