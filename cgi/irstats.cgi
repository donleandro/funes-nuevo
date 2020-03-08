#!/usr/bin/perl -w -I/usr/share/eprints3/perl_lib

##############################################################################
### Configuration ###
##############################################################################

# awstats modules
use lib "/usr/share/eprints3/perl_lib/AWStats/awstats-6.95/wwwroot/cgi-bin/lib/";

# ChartDirector
use lib "/usr/share/eprints3/perl_lib/ChartDirector";

use IRStats;
use EPrints;

# The path to IRStat's configuration file

##############################################################################
### End of Configuration ###
##############################################################################

use encoding 'utf8';
IRStats::handler();

1;

__END__

=head1 SYNOPSIS

B<irstats.pl> [OPTIONS] <ARGUMENTS>

=head1 OPTIONS

=over 8

=item --help

Print the help.

=item --man

Print the man page.

=item --config <config file>

Specify an alternate configuration file.

=item --verbose

Be more verbose (repeatable).

=back

=head1 ARGUMENTS

=over 4

=item COMMAND

The command to execute, see man page for details.

=back

=head1 COMMANDS

The following commands are available:

=over 4

=item update_metadata

Update metadata from repository.

=item update_table

Update the access log table from the database.

=item convert_ip_to_host

Convert IP addresses to hostnames in the database.

=back
