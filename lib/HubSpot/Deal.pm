package HubSpot::Deal;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;

# Make us a class
use Class::Tiny qw(json), qw/
    id
    amount
    amount_in_home_currency
    contract_type
    createdate
    days_to_close
    dealname
    dealstage
    dealtype
    description
    expected_duration_months_
    expected_open_date
    icro_project_type
    major_therapeutic_area_mta_
    pipeline
    pre_type
    icro_project_id
    icro_project_url
/;
use parent 'HubSpot::JSONBackedObject';

sub BUILD {
    my $self = shift;
    $self->{id} = $self->json->{dealId};
}

	
1;
