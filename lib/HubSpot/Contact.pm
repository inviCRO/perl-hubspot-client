package HubSpot::Contact;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;
use DateTime;

# Classes we need
use Data::Dumper;

# Make us a class
use subs qw(id primaryEmail firstName lastName company lastModifiedDateTime);
use Class::Tiny qw(id primaryEmail firstName lastName company lastModifiedDateTime),
{
		# Default variables in here
};
use parent 'HubSpot::JSONBackedObject';

sub name
{
	my $self = shift;
	
	return $self->firstName." ".$self->lastName;
}

sub id
{
	my $self = shift;
	
	$self->{'id'} = $self->json->{'vid'};
	
	return $self->{'id'};
}

sub firstName
{
	my $self = shift;
	
	$self->{'firstName'} = $self->json->{'properties'}->{'firstname'}->{'value'};
	
	return $self->{'firstName'};
}

sub lastName
{
	my $self = shift;
	
	$self->{'lastName'} = $self->json->{'properties'}->{'lastname'}->{'value'};
	
	return $self->{'lastName'};
}

sub company
{
	my $self = shift;
	
	$self->{'company'} = $self->json->{'properties'}->{'company'}->{'value'};
	
	return $self->{'company'};
}

sub lastModifiedDateTime
{
	my $self = shift;
	
	$self->{'lastModifiedDateTime'} = DateTime->from_epoch($self->json->{'properties'}->{'lastmodifieddate'}->{'value'});
	
	return $self->{'lastModifiedDateTime'};
}

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
	else
	{
		die("Couldn't find primary email address in contact. JSON retrieved from API:\n".Data::Dumper->Dump([$self->json]));
	} 
	
	return $self->{'primaryEmail'};
}

1;
