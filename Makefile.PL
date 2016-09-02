######################################################################
# Makefile.PL for HubSpot::Client
# 2016, Ian Gibbs <igibbs@cpan.org>
######################################################################
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'HubSpot::Client',
    'VERSION_FROM' => 'lib/HubSpot/Client.pm', # finds $VERSION
    'PREREQ_PM'    => {
		"Test::More" => "1",
		"REST::Client" => "273",
		"JSON" => "2.61",
    }
);
