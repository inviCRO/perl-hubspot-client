use warnings;
use strict;
use Test::More;
use HubSpot::Client;
use Data::Dumper;

BEGIN {}

my $hub_id = $ENV{'HUBSPOT_HUB_ID'};
my $hub_api_key = $ENV{'HUBSPOT_API_KEY'};
my $client = HubSpot::Client->new({ api_key => $hub_api_key, hub_id => $hub_id });

my $contacts = $client->contacts(3);
ok(1, "Retrieving specified number of contacts, below 250");
# Should get exactly the number we asked for back. All returned in one page
is(scalar(@$contacts), 3, "Counting returned number of owners");

# PROPERTIES
my $contact = $$contacts[0];
like($contact->id, qr/^\d{3,}/, "Checking contact ID is populated - '".$contact->id."'");
is(length($contact->firstName) > 0, 1, "Checking contact first name is populated - '".$contact->firstName."'");
is(length($contact->lastName) > 0, 1, "Checking contact last name is populated - '".$contact->lastName."'");
is(length($contact->company) > 0, 1, "Checking contact company is populated - '".$contact->company."'");

diag(Data::Dumper->Dump([$contact]));

my $username = qr/[a-z0-9_+]([a-z0-9_+.]*[a-z0-9_+])?/;
my $domain   = qr/[a-z0-9.-]+/;
like($contact->primaryEmail, qr/^$username\@$domain$/, "Checking contact email is populated - '".$contact->primaryEmail."'");

# PAGINATION
$contacts = $client->contacts(251);
# I'll be happy if it didn't crash
ok(1, "Retrieving specified number of contacts, above 250");
# Should get exactly the number we asked for back. Requires pagination
is(scalar(@$contacts), 251, "Counting returned number of owners");
# TO make sure we are getting different pages and adding them up and not just getting the same page
# (ie pagination is working), compare the first result of the first page to what should be the
# first result of the second page. They should have different ids
isnt($$contacts[0]->id, $$contacts[250]->id, "Getting successive pages");

done_testing();
