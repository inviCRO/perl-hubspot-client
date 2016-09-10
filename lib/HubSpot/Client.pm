package HubSpot::Client;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Modules
#use Log::Log4perl;
use REST::Client;
use Data::Dumper;
use JSON;
use HubSpot::Deal;
use HubSpot::Owner;

# Make us a class
use Class::Tiny qw(rest_client),
{
	api_key => 'demo',
	hub_id => '62515',
};

# Global variables
my $api_url = 'https://api.hubapi.com';
my $json = JSON->new;

sub BUILD
{
	my $self = shift;
	
	# Create ourselves a rest client to use
	$self->rest_client(REST::Client->new({ timeout => 20, host => $api_url, follow => 1 }));
}

sub deals
{
	my $self = shift;
	my $count = shift;
	
	$count = 100 unless defined $count;									# Max allowed by the API even though the doc says 500
	
	my $results = $json->decode($self->get('/deals/v1/deal/recent/modified', { count => $count }));
	my $deals = $results->{'results'};
	my $deal_objects = [];
	foreach my $deal (@$deals)
	{
		my $deal_object = HubSpot::Deal->new({json => $deal});
		push(@$deal_objects, $deal_object);
	}
	
	return $deal_objects;
}
		
sub owners
{
	my $self = shift;

	my $owners = $json->decode($self->get('/owners/v2/owners'));
	my $owner_objects = [];
	foreach my $owner (@$owners)
	{
		my $owner_object = HubSpot::Owner->new({json => $owner});
		push(@$owner_objects, $owner_object);
	}
	
	return $owner_objects;
}
			
sub get
{
	my $self = shift;
	my $path = shift;
	my $params = shift;
	
	$params = {} unless defined $params;								# In case no parameters have been specified
	$params->{'hapikey'} = $self->api_key;								# Include the API key in the parameters
	my $url = $path.$self->rest_client->buildQuery($params);			# Build the URL
	print STDERR $url."\n";
	$self->rest_client->GET($url);										# Get it
	$self->checkResponse();												# Check it was successful
	
	return $self->rest_client->responseContent();						# return the result
}
	
sub put
{
	my $self = shift;
	my $path = shift;
	my $params = shift;
	my $content = shift;
	
	$params = {} unless defined $params;								# In case no parameters have been specified
	$params->{'hapikey'} = $self->api_key;								# Include the API key in the parameters
	my $url = $path.$self->rest_client->buildQuery($params);			# Build the URL
	$self->rest_client->POST($url, $content);							# Get it
	$self->checkResponse();												# Check it was successful
	
	return $self->rest_client->responseContent();
}
	
sub checkResponse
{
	my $self = shift;
	
	if($self->rest_client->responseCode !~ /^[23]/)
	{
		die ("Request failed.
	Response Code: ".$self->rest_client->responseCode."
	Response Body: ".$self->rest_client->responseContent."
");
	}
}
