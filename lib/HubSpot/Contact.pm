package HubSpot::Contact;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;
use DateTime;

# Classes we need
use Data::Dumper;

=pod

=head1 NAME

HubSpot::Contact -- A read-only representation of a contact object in HubSpot

=head1 SYNOPSIS

 my $client = HubSpot::Client->new({ api_key => $hub_api_key }); 
 # Retrieve 50 contacts
 my $contacts = $client->contacts(50);

=head1 DESCRIPTION

This is the class returned by HubSpot::Client when it you execute methods that return contact objects. It is created from a blob of JSON taken from the HubSpot API, and so goes stale immediately.

=head1 METHODS

=cut

# Make us a class
use subs qw(id primaryEmail firstName lastName company lastModifiedDateTime);
use Class::Tiny qw(id primaryEmail firstName lastName company lastModifiedDateTime),
{
		# Default variables in here
};
use parent 'HubSpot::JSONBackedObject';

=pod

=over 4

=item new({json => <blob_of_json_from_hubspot_api> }) (constructor)

Instances of this object are usually created bu HubSpot::Client, which instnatiates them with a blob of JSON retrieved from the HubSpot API. When you access properties on this object the relevant data is pulled out rom the blob of JSON and returned.

Returns: new instance of this class.

=item new({primaryEmail => 'foo@bar.com', firstName => 'John', lastName => 'Smith'}) (constructor)

You can create instances of contacts and populate properties like this, but it will not cause the contact to be created in HubSpot. That will likely be implemented in future. Patches welcome.

Returns: new instance of this class.

=back

=head1 PROPERTIES

All properties can be retrieved by calling the relevant method, with no parameters. Setting properties is not currently supported.

 my $email = $contact->primaryEmail
 my $email = $contact->primaryEmail()
 
for example. Both do the same thing.

=over 4

=item id

The ID of the contact as it is known in HubSpot. You can use this to retrieve a specific contact only, rather than multiple contacts. See L<contact|HubSpot::Client/contact>

=cut
sub id
{
	my $self = shift;
	
	$self->{'id'} = $self->json->{'vid'};
	
	return $self->{'id'};
}

=pod

=item firstName

Returns the contact's first name, which is a mandatory field in HubSpot so this will always return something.

=cut
sub firstName
{
	my $self = shift;
	
	$self->{'firstName'} = $self->json->{'properties'}->{'firstname'}->{'value'};
	
	return $self->{'firstName'};
}

=pod

=item lastName

Returns the contact's first name, which is a mandatory field in HubSpot so this will always return something.

=cut
sub lastName
{
	my $self = shift;
	
	$self->{'lastName'} = $self->json->{'properties'}->{'lastname'}->{'value'};
	
	return $self->{'lastName'};
}

=pod

=item company

Returns the contact's associated company name, if set, or B<undef> otherwise.

=cut
sub company
{
	my $self = shift;
	
	$self->{'company'} = $self->json->{'properties'}->{'company'}->{'value'};
	
	return $self->{'company'};
}

=pod

=item lastModifiedDateTime

Returns the date and time that the contact was last modified, as a L<DateTime>, Time zone is UTC, but you can use that module's methods to change that.

=cut
sub lastModifiedDateTime
{
	my $self = shift;
	
	$self->{'lastModifiedDateTime'} = DateTime->from_epoch(epoch => $self->json->{'properties'}->{'lastmodifieddate'}->{'value'}/1000, time_zone => 'UTC');
	
	return $self->{'lastModifiedDateTime'};
}

=pod

=item primaryEmail

Returns the email address set as the primary email, if set, or B<undef> otherwise.

=cut
sub primaryEmail
{
	my $self = shift;
	
	my $profiles = $self->json->{'identity-profiles'};
	my $first_profile = $$profiles[0];						# other profiles may exist if it is a merged contact
	my $identities = $first_profile->{'identities'};
	my $found_email;
	foreach my $identity (@$identities)
	{
		if($identity->{'is-primary'} && $identity->{'type'} eq "EMAIL")
		{
			$found_email = $identity->{'value'};
		}
	}
	if($found_email)
	{
		$self->{'primaryEmail'} = $found_email;
	}
	# email isn't a compulsory field - might not be there
	
	return $self->{'primaryEmail'};
}

#~ sub name
#~ {
	#~ my $self = shift;
	
	#~ return $self->firstName." ".$self->lastName;
#~ }


=pod

=back

=cut

1;
