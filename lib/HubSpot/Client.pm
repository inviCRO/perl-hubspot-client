package HubSpot::Client;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Modules
#use Log::Log4perl;
use REST::Client;
use Data::Dumper;
use JSON;
use HubSpot::Contact;
use HubSpot::Deal;
use HubSpot::Owner;
use HubSpot::Company;

=pod

=head1 NAME

HubSpot::Client -- An object that can be used to manipulate the HubSpot API

=head1 SYNOPSIS

 my $client = HubSpot::Client->new({ api_key => $hub_api_key }); 
 # Retrieve 50 contacts
 my $contacts = $client->contacts(50);

=head1 DESCRIPTION

This module was created for internal needs. At the moment it does what I need it to do, which is to say not very much. However it is a decent enough framework for adding functionality to, so your contributions to extend it to what you need it to do are welcome.

At the moment you can only retrieve read-only representations of contact objects.

=head1 METHODS

=cut

# Make us a class
use Class::Tiny qw(rest_client),
{
	api_key => 'demo',
	hub_id => '62515',
};

# Global variables
my $api_url = 'https://api.hubapi.com';
my $json = JSON->new;
$json->utf8(1);

sub BUILD
{
	my $self = shift;
	
	# Create ourselves a rest client to use
	$self->rest_client(REST::Client->new({ timeout => 20, host => $api_url, follow => 1 }));
	
	if(length($self->{'api_key'}) > 0 && $self->{'api_key'} !~ /[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}/)
	{
		die("api_key doesn't look right. Should be a GUID like '6a2f41a3-c54c-fce8-32d2-0324e1c32e22'. You specified '".$self->{'api_key'}."'. To use the HubSpot demo account, don't specify api_key at all.");
	}
	if(length($self->{'api_key'}) < 1)
	{
		$self->{'api_key'} = 'demo';
	}
}

=pod

=over 4

=item new({api_key => <api_key_for_your hub> }) (constructor)

This class is what you use to perform actions against the API. Once you have created an instance of this object, you can call the other methods below on it. If you don't specify an API key it will connect to the demo HubSpot hub. Since this is shared by everyone on the internet, don't be surprised if you start to see 429 errors getting returned. See L<Rate limits|https://developers.hubspot.com/apps/api_guidelines>. 

Returns: new instance of this class.

=cut

#~ sub deals_recently_modified
#~ {
	#~ my $self = shift;
	#~ my $count = shift;
	
	#~ $count = 100 unless defined $count;									# Max allowed by the API
	
	#~ my $results = $json->decode($self->_get('/deals/v1/deal/recent/modified', { count => $count }));
	#~ my $deals = $results->{'results'};
	#~ my $deal_objects = [];
		#~ foreach my $deal (@$deals)
	#~ {
		#~ my $deal_object = HubSpot::Deal->new({json => $deal});
		#~ push(@$deal_objects, $deal_object);
	#~ }
	
	#~ return $deal_objects;
#~ }
		
=item contact_by_id()

Retrieve a single contact record by its ID. Takes one parameter, which is the ID of the contact you want to retrieve. The returned object will contain all the properties set on that object.

 my $contact = $client->contact_by_id('897654');

Returns: L<HubSpot::Contact>, or undef if the contact wasn't found.

=cut

sub contact_by_id
{
	my $self = shift;
	my $id = shift;
	
	my $content = $self->_get("/contacts/v1/contact/vid/$id/profile", { propertyMode => 'value_only' });
	return undef if	$self->rest_client->responseCode =~ /^404$/;
	my $result = $json->decode($content);
	return HubSpot::Contact->new({json => $result});
}

sub contact_by_email
{
	my $self = shift;
	my $id = shift;
	
	my $content = $self->_get("/contacts/v1/contact/email/$id/profile", { propertyMode => 'value_only' });
	return undef if	$self->rest_client->responseCode =~ /^404$/;
	my $result = $json->decode($content);
	return HubSpot::Contact->new({json => $result});
}

=item contacts()

Retrieve all contact records. Takes one optional parameter, which is the number of contacts you want to retrieve. The returned objects will contain a few of the properties set on that object. See L<HubSpot::Client/properties>.

 my $contact = $client->contacts();
 my $contact = $client->contacts(200);
s
Returns: L<HubSpot::Contact>

=cut

sub contacts
{
	my $self = shift;
    my $type = shift || 'all';
	my $param = shift;

	my $count = 100;									# Max allowed by the API
	
	my $contact_objects = [];
	my $offset;
	my $results;
	my $i = 0;
    my $URL_BASE = '/contacts/v1/lists';
    my %URLS = ( 
        all     => "$URL_BASE/all/contacts/all",
        recent  => "$URL_BASE/recently_updated/contacts/recent",
        created => "$URL_BASE/all/contacts/recent",
    );
    my $url = $URLS{$type} || $URLS{all};
    my @options;
    if ($param->{properties} and ref $param->{properties} eq 'ARRAY') {
        push @options, 'property', $_ for @{ $param->{properties} }; # this means only one is supported XXX, have to rewrite to be array
    }
    if ($param->{timeOffset}) {
        push @options, timeOffset => $param->{timeOffset};
    }

	while(!defined($results) || $results->{'has-more'} == 1)
	{
		$i++;
		if($offset)
		{
			$results = $json->decode($self->_get($url, { @options, count => $count, vidOffset => $offset }));
		}
		else
		{
			$results = $json->decode($self->_get($url, { @options, count => $count }));
		}
		my $contacts = $results->{'contacts'};
		foreach my $contact (@$contacts)
		{
			my $contact_object = HubSpot::Contact->new({json => $contact});
			push(@$contact_objects, $contact_object);
		}
		$offset = $results->{'vid-offset'};
        # if(scalar(@$contact_objects) >= $count)
		# {
		# 	my @slice = @$contact_objects[0..$count-1]; $contact_objects = \@slice;
		# 	last;
		# }
	}
	
	return $contact_objects;
}

#~ sub owners
#~ {
	#~ my $self = shift;

	#~ my $owners = $json->decode($self->_get('/owners/v2/owners'));
	#~ my $owner_objects = [];
	#~ foreach my $owner (@$owners)
	#~ {
		#~ my $owner_object = HubSpot::Owner->new({json => $owner});
		#~ push(@$owner_objects, $owner_object);
	#~ }
	
	#~ return $owner_objects;
#~ }

#~ sub logMeeting
#~ {
	#~ my $self = shift;
	#~ my $deal = shift;
	#~ my $date = shift;
#~ }	
			
sub _get {
	my $self = shift;
	my $path = shift;
	my $params = shift;
	
	$params = {} unless defined $params;								# In case no parameters have been specified
	$params->{'hapikey'} = $self->api_key;								# Include the API key in the parameters
	my $url = $path.$self->rest_client->buildQuery($params);			# Build the URL
    # warn $url, "\n";
	$self->rest_client->GET($url);										# Get it
	$self->_checkResponse();											# Check it was successful
	
	return $self->rest_client->responseContent();						# return the result
}
	
sub _post {
	my $self = shift;
    return $self->_request(POST => @_);
}

sub _put {
    my $self = shift;
    return $self->_request(PUT => @_);
}

sub _request {
	my $self = shift;
    my $method = shift;
	my $path = shift;
	my $params = shift;
	my $content = shift;
	
	$params = {} unless defined $params;								# In case no parameters have been specified
	$params->{'hapikey'} = $self->api_key;								# Include the API key in the parameters
	my $url = $path.$self->rest_client->buildQuery($params);			# Build the URL
    my $header = { 'Content-Type' => 'application/json' };
	my $res = $self->rest_client->request( $method, $url, $content, $header);			# GET/POST/PUT itlication/json' };
	$self->_checkResponse();											# Check it was successful
	
	return $self->rest_client->responseContent();
}
	
sub _checkResponse {
	my $self = shift;
	
	if ($self->rest_client->responseCode !~ /^[23]|404/) {
		die ("Request failed.
	Response Code: ".$self->rest_client->responseCode."
	Response Body: ".$self->rest_client->responseContent."
");
	}
}

sub update {
    my ($self, $type, $id, $prop) = @_;
    return unless ref $prop eq 'HASH';
    my %URLMAP = (
        user => "/contacts/v1/contact/vid/$id/profile",
        deal => "/deals/v1/deal/$id",
    );
    my %METHODMAP = (
        user => 'POST',
        deal => 'PUT',
    );
    my %NAMEMAP = (
        user => 'property',
        deal => 'name',
    );
    return unless exists $URLMAP{$type};
    my $url = $URLMAP{ $type };
    my $method = $METHODMAP{ $type };

    my @list;
    for my $k (keys %$prop) {
        next unless length $k;
        push @list, { $NAMEMAP{$type} => $k, value => $prop->{$k} || '' }
    }
    my $data = $json->encode( { properties => \@list } );
    my $res = $self->_request( $method => $url, {}, $data ); 
    # use Data::Dumper::Concise;
    # print Dumper $res;
    return $res;
}

sub deals {
	my $self = shift;
    my $type = shift || 'all';
	my $param = shift;

	my $count = 100;									# Max allowed by the API
	
	my $deal_objects = [];
	my $offset;
	my $i = 0;
    my $URL_BASE = '/deals/v1/deal';
    my %URLS = ( 
        all     => "$URL_BASE/paged",
        recent  => "$URL_BASE/recent/modified",
        created => "$URL_BASE/recent/created",
    );
    my $url = $URLS{$type} || $URLS{all};
    my @options;
    if ($param->{properties} and ref $param->{properties} eq 'ARRAY') {
        push @options, 'property', $_ for @{ $param->{properties} };
    }
    if ($param->{since}) {
        push @options, since => $param->{since};
    }

    my $results;
	while ( !defined($results) || $results->{'has-more'} == 1 ) {
		$i++;
        my $response;
		if ($offset) {
			$response = $self->_get($url, { @options, count => $count, offset => $offset });
		} else {
			$response = $self->_get($url, { @options, count => $count });
		}
        $results = $json->decode( $response );

		my $deals = $results->{'results'};
		foreach my $deal (@$deals) {
			my $deal_object = HubSpot::Deal->new({json => $deal});
			push(@$deal_objects, $deal_object);
		}
		$offset = $results->{'offset'};
	}
	
	return $deal_objects;
}

sub deal_by_id {
	my $self = shift;
	my $id = shift;
	
	my $content = $self->_get("/deals/v1/deal/$id");
	return undef if	$self->rest_client->responseCode =~ /^404$/;
	my $result = $json->decode($content);
	return HubSpot::Deal->new({json => $result});
}

sub owner_by_id {
	my $self = shift;
	my $id = shift;
	
	my $content = $self->_get("/owners/v2/owners/$id");
	return if	$self->rest_client->responseCode =~ /^404$/;
	my $result = $json->decode($content);
	return HubSpot::Owner->new({json => $result});
}

sub company_by_id {
    my $self = shift;
    my $id = shift;

	my $content = $self->_get("/companies/v2/companies/$id");
    # warn "Company $id:", Dumper $content, "\n";
	return if	$self->rest_client->responseCode =~ /^404$/;
	my $result = $json->decode($content);
	return HubSpot::Company->new({json => $result});
}

sub associations {
    my $self = shift;
    my ($type, $id) = @_;

    my $url = "/crm-associations/v1/associations/$id/HUBSPOT_DEFINED/$type";
    my $res = $self->_get( $url );
	return if	$self->rest_client->responseCode =~ /^404$/;
    my $data = $json->decode( $res );
    my $res = $data->{results};
    return unless ref $res;
    return wantarray ? @$res : $res;
}

