package HubSpot::JSONBackedObject;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;
use Time::Piece;

# Classes we need
use Data::Dumper;

# Make us a class
use Class::Tiny qw(properties id),
{
	json => undef,
};

sub BUILD
{
	my ($self, $args) = @_;

    # warn "===================\n";
    # warn Dumper $args;
    # warn "===================\n";
	
	if(defined($args->{'json'})) {
		# Not actually JSON but a perl object derived from the JSON response
		$self->json($args->{'json'});
        if (defined $self->json->{id}) {
            $self->id( $self->json->{id} );
        }
	}
	
	if (defined($self->json->{'properties'})) {
        $self->properties( $self->json->{properties} );
	} elsif (ref $self eq 'HubSpot::Owner') {
        $self->properties({});
        for my $p (qw/email firstName lastName isActive type updatedAt createdAt/) {
            $self->properties->{$p} = $self->json->{$p};
        }
    } elsif (ref $self eq 'HubSpot::Property') {
        for my $attr (Class::Tiny->get_all_attributes_for("HubSpot::Property")) {
            next if exists $self->{$attr};
            $self->{$attr} = $self->json->{$attr};
        }
    }

# warn "REF: ", ref $self, "\n";
    for my $attr ( Class::Tiny->get_all_attributes_for(ref $self) ) {
        next if defined $self->{ $attr };
# warn "attr($attr)=", $self->{properties}{ $attr }, "\n";
        $self->{ $attr } = $self->{properties}{ $attr };
        if ($attr =~ /(?:date|At)$|^date/ and $self->{$attr} > 0) {
            ( my $date = $self->{ $attr } ) =~ s/(?:\.\d{3})?Z$//; # remove ms and timezone Z (.000Z)
            $self->{ $attr } = eval{ Time::Piece->strptime( $date, "%Y-%m-%dT%H:%M:%S" ) };
            warn "WARN: Could not parse date $attr=$date: $@\n" if $@;
        }
    }
}

sub getProperty {
	my ( $self, $key ) = @_;
	return $self->properties->{$key};
}
	
1;
