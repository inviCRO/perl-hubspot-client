package HubSpot::Client;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Modules
#use Log::Log4perl;
use REST::Client;
use Data::Dumper::Concise;
use JSON;
use HubSpot::Contact;
use HubSpot::Deal;
use HubSpot::Owner;
use HubSpot::Company;
use HubSpot::Property;

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
    keymap => undef,
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

sub contact_by_id {
	my ($self, $id, $prop, $assoc, $extra) = @_;
	
    my @properties = Class::Tiny->get_all_attributes_for("HubSpot::Contact");
    push @properties, @$prop if ref $prop eq 'ARRAY';
    my %param = ( properties => join(',', @properties) );
    $param{associations} = join(',', @$assoc) if ref $assoc eq 'ARRAY';
    if (ref $extra eq 'HASH') { $param{$_} = $extra->{$_} for keys %$extra }
	my $content = $self->_get("/crm/v3/objects/contacts/$id", \%param);
	return undef if	$self->rest_client->responseCode =~ /^404$/;
	my $result = $json->decode($content);
	return HubSpot::Contact->new({json => $result});
}

sub contact_by_email {
    my ($self, $email) = @_;
    return $self->contact_by_id($email, undef, undef, { idProperty => 'email' });
}

=item contacts()

Retrieve all contact records. Takes one optional parameter, which is the number of contacts you want to retrieve. The returned objects will contain a few of the properties set on that object. See L<HubSpot::Client/properties>.

 my $contact = $client->contacts();
 my $contact = $client->contacts(200);
s
Returns: L<HubSpot::Contact>

=cut

sub contacts {
    my ($self, $extra) = @_;
    my $limit = 100;
	my $contact_objects = [];
    my $url = '/crm/v3/objects/contacts';

    my %param = (
        limit => $limit,
        after => 0,
        properties => [ join(',', Class::Tiny->get_all_attributes_for("HubSpot::Contact")) ],
        ( ref $extra ? %$extra : () ),
    );
	my $results;
	while(1) {
        my $res = eval{ $self->_get($url, \%param) };
        if ($@) {
            die "ERROR: $@\n", Dumper $url, \%param;
        }
        $results = $json->decode( $res );
		my $contacts = $results->{'results'};
		foreach my $contact (@$contacts) {
			my $contact_object = HubSpot::Contact->new({json => $contact});
			push(@$contact_objects, $contact_object);
		}
        if ($results->{paging}) {
            $param{after} = $results->{paging}{next}{after};
        } else { last }
        __sleep(150); # sleep 150ms to keep 100/10s rate
    }

	return $contact_objects;
}

# has a max of 10,000 results returned (even when paged)
sub contacts_search {
	my ( $self, $filters, $extra ) = @_;

	my $limit = 100; # Max allowed by the API
	my $contact_objects = [];
    my $url = '/crm/v3/objects/contacts/search';

    my %param = (
        limit => $limit,
        after => 0,
        properties => [ join(',', Class::Tiny->get_all_attributes_for("HubSpot::Contact")) ],
        ( ref $extra ? %$extra : () ),
    );
    $param{sorts} = [
        { propertyName => 'lastmodifieddate', direction => 'DESCENDING' }
    ];
    my @filters;
    if (defined $filters) {
        for my $f (@$filters) {
            my ($k,$v,$op) = split '#', $f;
            push @filters, { value => $v, propertyName => $k, operator => $op };
        }
        $param{filterGroups} = [{
            filters => \@filters
        }] if @filters;
    }

	my $results;
	while(1) {
# warn "url=$url\n";
# local $Data::Dumper::Maxdepth = 5;
# warn "param=", Dumper \%param;
        my $res = eval{ $self->_post($url, {}, \%param) };
        if ($@) {
            die "ERROR: $@\n", Dumper $url, \%param;
        }
        $results = $json->decode( $res );
# warn Dumper $results;
		my $contacts = $results->{'results'};
		foreach my $contact (@$contacts) {
			my $contact_object = HubSpot::Contact->new({json => $contact});
			push(@$contact_objects, $contact_object);
		}
        if ($results->{paging}) {
            $param{after} = $results->{paging}{next}{after};
        } else { last }
        __sleep(150); # sleep 150ms to keep 100/10s rate
	}
	
	return $contact_objects;
}

sub contacts_recently_changed {
    my ($self, $since) = @_;
    my $dt = DateTime->now->add( seconds => -$since );
    my $recent = $dt->epoch * 1000;
    return $self->contacts_search( ["lastmodifieddate#$recent#GT"] );
}

sub companies_recently_changed {
    my ($self, $since) = @_;
    my $dt = DateTime->now->add( seconds => -$since );
    my $recent = $dt->epoch * 1000;
    return $self->companies_search( ["hs_lastmodifieddate#$recent#GT"] );
}

sub deals_recently_changed {
    my ($self, $since) = @_;
    my $dt = DateTime->now->add( seconds => -$since );
    my $recent = $dt->epoch * 1000;
    return $self->deals_search( ["hs_lastmodifieddate#$recent#GT"] );
}

sub contacts_recently_changed {
    my ($self, $since) = @_;
    my $dt = DateTime->now->add( seconds => -$since );
    my $recent = $dt->epoch * 1000;
    return $self->contacts_search( ["lastmodifieddate#$recent#GT"] );
}

sub __sleep {
    select( undef, undef, undef, $_[0]/1000 )
}

sub owners {
    my $self = shift;

    my $res = $self->_get('/crm/v3/owners');
    my $results = $json->decode($res);
    my $objects = [];
    foreach my $owner (@{ $results->{results} }) {
        my $obj = HubSpot::Owner->new({json => $owner});
        push(@$objects, $obj);
    }

    return $objects;
}

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
    if (ref $params eq 'ARRAY') {
        push @$params, hapikey => $self->api_key;								# Include the API key in the parameters
    } else {
        $params->{'hapikey'} = $self->api_key;								# Include the API key in the parameters
    }

	my $url = $path.$self->rest_client->buildQuery($params);			# Build the URL
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

    if (ref $content) { $content = $json->encode( $content ) }
	
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

sub create {
    my ($self, $type, $prop, $assoc) = @_;
    my %URLMAP = (
        deal => '/crm/v3/objects/deals/',
    );
    my $url = $URLMAP{$type} or die "Unknown type $type\n";

    my %param = ( properties => $prop );
    $param{associations} = $assoc if ref $assoc;
    my $data = $json->encode( \%param );
    # warn "CREATE url: $url\n";
    # warn "CREATE data: ======\n", Dumper $data, "\n===========\n";
    # warn Dumper \%param, "========\n";
    my $res = $self->_request( POST => $url, {}, $data ); 
    my $result = $json->decode( $res );
    my $module = "HubSpot::".ucfirst($type);
	return $module->new({json => $result});
}


sub update {
    my ($self, $type, $id, $prop) = @_;
    return unless ref $prop eq 'HASH';
    return if $type eq 'owner'; # nothing to do here
    my %URLMAP = (
        contact => "/crm/v3/objects/contacts/$id",
        company => "/crm/v3/objects/companies/$id",
        deal    => "/crm/v3/objects/deals/$id",
    );
    die "ERROR: update: unsupported type '$type'\n" unless exists $URLMAP{$type};
    my $url = $URLMAP{ $type };

    my $data = $json->encode( { properties => $prop } );
    my $res = $self->_request( PATCH => $url, {}, $data ); 
    my $result = eval { $json->decode( $res ) };
    if ($@) {
        die "ERROR: $@\n", Dumper $res;
    }
    my $module = "HubSpot::".ucfirst($type);
	return $module->new({json => $result});
}

sub deals {
    my ($self, $extra) = @_;
    my $limit = 100;
	my $objects = [];
    my $url = '/crm/v3/objects/deals';

    my %param = (
        limit => $limit,
        after => 0,
        properties => [ join(',', Class::Tiny->get_all_attributes_for("HubSpot::Deal")) ],
        ( ref $extra ? %$extra : () ),
    );
	my $results;
	while(1) {
        my $res = eval{ $self->_get($url, \%param) };
        if ($@) {
            die "ERROR: $@\n", Dumper $url, \%param;
        }
        $results = $json->decode( $res );
		foreach my $data (@{ $results->{results} }) {
			my $obj = HubSpot::Deal->new({json => $data});
            $self->__apply_keymap_to_deal( $obj );
			push(@$objects, $obj);
		}
        if ($results->{paging}) {
            $param{after} = $results->{paging}{next}{after};
        } else { last }
        __sleep(150); # sleep 150ms to keep 100/10s rate
    }

	return $objects;
}

sub deal_by_id {
	my ($self, $id, $prop, $assoc, $extra) = @_;
	
    my @properties = Class::Tiny->get_all_attributes_for("HubSpot::Deal");
    push @properties, @$prop if ref $prop eq 'ARRAY';
    my %param = ( properties => join(',', @properties) );
    $param{associations} = join(',', @$assoc) if ref $assoc eq 'ARRAY';
    if (ref $extra eq 'HASH') { $param{$_} = $extra->{$_} for keys %$extra }
	my $content = $self->_get("/crm/v3/objects/deals/$id", \%param);
	return undef if	$self->rest_client->responseCode =~ /^404$/;
	my $result = $json->decode($content);
	my $deal = HubSpot::Deal->new({json => $result});
    $self->__apply_keymap_to_deal( $deal );
    return $deal;
}

sub deals_search {
	my ( $self, $filters, $extra ) = @_;

	my $limit = 10; # Max allowed by the API
	my $objects = [];
    my $url = '/crm/v3/objects/deals/search';

    my %param = (
        limit => $limit,
        after => 0,
        properties => [ join(',', Class::Tiny->get_all_attributes_for("HubSpot::Deal")) ],
        ( ref $extra ? %$extra : () ),
    );
    $param{sorts} = [
        { propertyName => 'hs_lastmodifieddate', direction => 'DESCENDING' }
    ];
    my @filters;
    if (defined $filters) {
        for my $f (@$filters) {
            my ($k,$v,$op) = split '#', $f;
            push @filters, { value => $v, propertyName => $k, operator => $op };
        }
        $param{filterGroups} = [{
            filters => \@filters
        }] if @filters;
    }

	my $results;
	while(1) {
        my $res = eval{ $self->_post($url, {}, \%param) };
        if ($@) {
            die "ERROR: $@\n", Dumper $url, \%param;
        }
        $results = $json->decode( $res );
		foreach my $data (@{ $results->{results} }) {
			my $obj = HubSpot::Deal->new({json => $data});
            $self->__apply_keymap_to_deal( $obj );
			push(@$objects, $obj);
		}
        if ($results->{paging}) {
            $param{after} = $results->{paging}{next}{after};
        } else { last }
        __sleep(150); # sleep 150ms to keep 100/10s rate
	}
	
	return $objects;
}

sub __apply_keymap_to_deal {
    my ($self, $deal) = @_;

    if (ref $self->keymap and $deal->pipeline) {
        my $pipeline = $self->keymap->{pipelines}{ $deal->pipeline };
        if ($pipeline) {
            # print "Found Pipeline $pipeline->{name}\n";
            $deal->{dealstage_id} = $deal->{dealstage};
            $deal->{dealstage} = $pipeline->{ $deal->{dealstage} } || "Unknown($deal->{dealstage})";
        }
    }
}

sub owner_by_id {
	my $self = shift;
	my $id = shift;
	
	my $content = $self->_get("/owners/v2/owners/$id");
	return if $self->rest_client->responseCode =~ /^404$/;
	my $result = $json->decode($content);
	return HubSpot::Owner->new({json => $result});
}

sub company_by_id {
	my ($self, $id, $prop, $assoc, $extra) = @_;

    my @properties = Class::Tiny->get_all_attributes_for("HubSpot::Company");
    push @properties, @$prop if ref $prop eq 'ARRAY';
    my %param = ( properties => join(',', @properties) );
    $param{associations} = join(',', @$assoc) if ref $assoc eq 'ARRAY';
    if (ref $extra eq 'HASH') { $param{$_} = $extra->{$_} for keys %$extra }
	my $content = $self->_get("/crm/v3/objects/companies/$id", \%param);
	return if $self->rest_client->responseCode =~ /^404$/;
	my $result = $json->decode($content);
	return HubSpot::Company->new({json => $result});
}

# has a max of 10,000 results returned (even when paged)
sub companies_search {
	my ( $self, $filters, $extra ) = @_;

	my $limit = 10; # Max allowed by the API
	my $company_objects = [];
    my $url = '/crm/v3/objects/companies/search';

    my %param = (
        limit => $limit,
        after => 0,
        properties => [ join(',', Class::Tiny->get_all_attributes_for("HubSpot::Company")) ],
        ( ref $extra ? %$extra : () ),
    );
    $param{sorts} = [
        { propertyName => 'hs_lastmodifieddate', direction => 'DESCENDING' }
    ];
    my @filters;
    if (defined $filters) {
        for my $f (@$filters) {
            my ($k,$v,$op) = split '#', $f;
            push @filters, { value => $v, propertyName => $k, operator => $op };
        }
        $param{filterGroups} = [{
            filters => \@filters
        }] if @filters;
    }

	my $results;
	while(1) {
# warn "url=$url\n";
# local $Data::Dumper::Maxdepth = 5;
# warn "param=", Dumper \%param;
        my $res = eval{ $self->_post($url, {}, \%param) };
        if ($@) {
            die "ERROR: $@\n", Dumper $url, \%param;
        }
        $results = $json->decode( $res );
		my $companies = $results->{'results'};
		foreach my $data (@$companies) {
			my $obj = HubSpot::Company->new({json => $data});
			push(@$company_objects, $obj);
		}
        if ($results->{paging}) {
            $param{after} = $results->{paging}{next}{after};
        } else { last }
        __sleep(150); # sleep 150ms to keep 100/10s rate
	}
	
	return $company_objects;
}

sub associations {
    my ($self, $from, $id, $to) = @_;
    my $url = "/crm/v3/associations/$from/$to/batch/read";
    my $res = $self->_post( $url, {}, { inputs => [{ id => $id }] } );
	return if $self->rest_client->responseCode =~ /^404$/;
    my $data = $json->decode( $res );
    my $res = $data->{results};
    return unless ref $res;

    # local $Data::Dumper::Maxdepth = 5;
    my $method = "${to}_by_id";
    my @res;
    for my $r (@$res) {
        # print Dumper $r, $method;
        for my $i ( @{ $r->{to} } ) {
            my $id = $i->{id};
            if ($self->can($method)) {
                my $obj = $self->$method( $id );
                push @res, $obj;
            } else {
                push @res, $r;
            }
        }
    }
    return wantarray ? @res : shift @res;
}

sub add_assoc_v1 {
    my $self = shift;
    my ($type, $from, $to) = @_;

    my $url = "/crm-associations/v1/associations";
    my %param = (
        category => "HUBSPOT_DEFINED",
        definitionId => $type,
        fromObjectId => $from,
        toObjectId => $to,
    );
    my $data = $json->encode( \%param );
    my $res = $self->_request( PUT => $url, {}, $data ); 
    return $res;
}

sub del_assoc_v1 {
    my $self = shift;
    my ($type, $from, $to) = @_;
    my $url = '/crm-associations/v1/associations/delete';
    my %param = (
        category => 'HUBSPOT_DEFINED',
        definitionId => $type,
        fromObjectId => $from,
        toObjectId => $to,
    );
    my $data = $json->encode( \%param );
    my $res = $self->_request( PUT => $url, {}, $data );
    return $res;
}

sub del_assoc {
    my ($self, $from, $fid, $to, $tid, $atype) = @_;
    my $atype = "${from}_to_${to}";
    my $url = "/crm/v3/associations/$from/$to/batch/archive";
    my %param = (
        inputs => [
            {
                from => { id => $fid },
                to => { id => $tid },
                type => $atype,
            }
        ]);
    my $data = $json->encode( \%param );
    my $res = $self->_request( POST => $url, {}, $data );
    return $res;
}

sub list_assoc {
    my ($self, $from, $to) = @_;
    my $url = "/crm/v3/associations/$from/$to/types";
    my $res = $self->_request( GET => $url );
    return $res;
}

sub add_assoc {
    my ($self, $from, $fid, $to, $tid, $atype, $replace) = @_;

    $atype //= "${from}_to_${to}";

    if (defined $replace and $replace) {
        while (1) {
            my $res = $self->associations($from, $fid, $to);
            if (defined $res and $res->{id} and $res->{id} != $tid) {
                print "  UPDATE: Replacing $atype association between $fid:$res->{id}\n";
                my $res = $self->del_assoc($from, $fid, $to, $res->{id});
            } else {
                last;
            }
        }
    }

    my $url = "/crm/v3/associations/$from/$to/batch/create";
    my %param = (
        inputs => [
            {
                from => { id => $fid },
                to => { id => $tid },
                type => $atype,
            }
        ]);
    my $data = $json->encode( \%param );
    my $res = $self->_request( POST => $url, {}, $data );
    my $results = $json->decode( $res );
    return $results;
}

sub companies {
    my ($self, $extra) = @_;
    my $limit = 100;
	my $company_objects = [];
    my $url = '/crm/v3/objects/companies';

    my %param = (
        limit => $limit,
        after => 0,
        properties => [ join(',', Class::Tiny->get_all_attributes_for("HubSpot::Company")) ],
        ( ref $extra ? %$extra : () ),
    );
	
    my $results;
	while (1) {
        my $res = eval{ $self->_get($url, \%param) };
        if ($@) {
            die "ERROR: $@\n", Dumper $url, \%param;
        }
        $results = $json->decode( $res );
		foreach my $data (@{ $results->{results} }) {
			my $obj = HubSpot::Company->new({json => $data});
			push @$company_objects, $obj;
		}
        if ($results->{paging}) {
            $param{after} = $results->{paging}{next}{after};
        } else { last }
        __sleep(150); # sleep 150ms to keep 100/10s rate
	}
	
	return $company_objects;
}

sub properties {
    my ($self, $type) = @_;
    my %URLMAP = (
        deals => '/properties/v1/deals/properties',
    );
    my $url = $URLMAP{$type};
    die "Unknown type '$type'" unless defined $url;

    my $res = $self->_get( $url );
    my $data = $json->decode( $res );
    return $data;
}

sub property {
    my ($self, $type, $name) = @_;
    my %URLMAP = (
        deal => '/properties/v1/deals/properties/named/',
    );
    my $url = $URLMAP{$type} . $name;
    die "Unknown type '$type'" unless exists $URLMAP{$type};

    my $res = $self->_get( $url );
    my $data = $json->decode( $res );
    my $obj = HubSpot::Property->new({json => $data});
    return $obj;
}
