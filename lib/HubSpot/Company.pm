package HubSpot::Company;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;

# Make us a class
use Class::Tiny qw(json id 
    domain description address address2 annualrevenue city country createdate facebook_company_page
    first_deal_created_date founded_year industry is_public lifecyclestage linkedin_company_page linkedinbio
    name num_associated_deals numberofemployees phone state timezone twitterhandle
    web_technologies website zip
);
use parent 'HubSpot::JSONBackedObject';

sub BUILD {
    my $self = shift;
    $self->{id} = $self->{json}{companyId};
}

1;
