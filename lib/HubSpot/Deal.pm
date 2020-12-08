package HubSpot::Deal;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;

# Make us a class
use parent 'HubSpot::JSONBackedObject';
use Class::Tiny qw/
    amount
    amount_in_home_currency
    completion_date
    contract_lead
    contract_type
    createdate
    date_received
    days_to_close
    dealname
    dealstage
    dealtype
    delivery_date
    description
    due_date
    expected_duration_months_
    expected_open_date
    icro_project_id
    icro_project_type
    icro_project_url
    precontractid
    internal_team_meeting_date
    major_therapeutic_area_mta_
    open_date
    pipeline
    precontract_id
    precontract_url
    pre_type
    vip
    hubspot_owner_id

    anatomy
    deal_currency_code
    modalities
    phase
    population_age
    revenue_to_date
    service_areas
/;

	
1;
