package HubSpot::Property;
our $VERSION = "0.01";
use strict;

use Data::Dumper;

use Class::Tiny qw(json), qw/
    name
    label
    description
    groupName
    type
    fieldType
    options
    formField
    displayOrder
    readOnlyValue
    readOnlyDefinition
    hidden
    mutableDefinitionNotDeletable
    calculated
    externalOptions
    displayMode
    hubspotDefined

    options_hash
    options_list
/;

use parent 'HubSpot::JSONBackedObject';

sub BUILD {
    my $self = shift;

    $self->options_hash({});
    $self->options_list([]);
    if (ref $self->{options} eq 'ARRAY') {
        for my $o (@{ $self->{options} }) {
            next unless ref $o eq 'HASH';
            $self->{options_hash}{$o->{label}} = $o->{value};
            push @{ $self->options_list }, $o->{label};
        }
    }
}


1; # keep require happy
