use warnings;
use strict;
use Test::More;
use HubSpot::Client;
use Data::Dumper;

BEGIN {}

my $client = HubSpot::Client->new();

my $owners = $client->owners();
# I'll be happy if it didn't crash
ok(1, "Retrieving owners");
# Should get more than 0 back
ok(scalar(@$owners) > 0, "Counting returned number of owners");

my $owner = $$owners[0];
ok($owner->name, "Checking owner name is populated - '".$owner->name."'");
ok($owner->id, "Checking owner ID is populated - '".$owner->id."'");
ok($owner->firstName, "Checking owner first name is populated - '".$owner->firstName."'");
ok($owner->lastName, "Checking owner ID is populated - '".$owner->lastName."'");
ok($owner->email, "Checking owner name is populated - '".$owner->email."'");

done_testing();
