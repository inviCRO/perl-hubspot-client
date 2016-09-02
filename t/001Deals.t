use warnings;
use strict;
use Test::More tests => 1;
use HubSpot::Client;

BEGIN {}

my $client = HubSpot::Client->new();

ok($client->deals, "Getting deals");
