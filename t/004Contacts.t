use warnings;
use strict;
use Test::More;
use HubSpot::Client;
use Data::Dumper;

BEGIN {}

my $client = HubSpot::Client->new();

my $contacts = $client->contacts(3);
# I'll be happy if it didn't crash
ok(1, "Retrieving contacts");
# Should get more than 0 back
ok(scalar(@$contacts) > 0, "Counting returned number of owners");

my $contact = $$contacts[0];
#ok($contact->name, "Checking contact name is populated - '".$contact->name."'");
ok($contact->id, "Checking contact ID is populated - '".$contact->id."'");
print Dumper $contact;

#ok($contact->firstName, "Checking contact first name is populated - '".$contact->firstName."'");
#ok($contact->lastName, "Checking contact ID is populated - '".$contact->lastName."'");
#ok($contact->email, "Checking contact name is populated - '".$contact->email."'");

done_testing();