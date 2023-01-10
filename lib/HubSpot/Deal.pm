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
    site
    contract_value
    expected_main_lab_resource_dps_
    expected_subcontractor_fees
    emerging_business
    sponsor_site
    sponsor_po
    createdate
    closedate
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
    secondary_therapeutic_areas_sta_
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
    species
    population_age
    revenue_to_date
    service_areas
    distributor

    lost_date
    closed_lost_reason
    reason_lost_notes
/;

	
1;
