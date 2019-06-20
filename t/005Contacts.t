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
# I'll be happy if it didn't crash
ok(1, "Retrieving specified number of contacts, below 100");
# Should get exactly the number we asked for back
is(scalar(@$contacts), 3, "Counting returned number of owners");

$contacts = $client->contacts(120);
# I'll be happy if it didn't crash
ok(1, "Retrieving specified number of contacts, above 100");
# Should get exactly the number we asked for back
is(scalar(@$contacts), 120, "Counting returned number of owners");

my $contact = $$contacts[0];
#ok($contact->name, "Checking contact name is populated - '".$contact->name."'");
ok($contact->id, "Checking contact ID is populated - '".$contact->id."'");
diag(Data::Dumper->Dump([$contact]));

my $username = qr/[a-z0-9_+]([a-z0-9_+.]*[a-z0-9_+])?/;
my $domain   = qr/[a-z0-9.-]+/;
ok($contact->primaryEmail =~ /^$username\@$domain$/, "Checking contact email is populated - '".$contact->primaryEmail."'");



done_testing();
