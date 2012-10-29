#!/usr/bin/perl -Tw

# Copyright 2012 Jean-Sebastien Morisset (http://surniaulula.com/).
#
# This script is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# This script is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details at http://www.gnu.org/licenses/.

# Create and update OTRS tickets from Centreon, Nagios, other monitoring
# systems or the command-line.
#
# Centreon->Configuration->Commands->Notifications->host-notify-otrs-ticket:
#	$USER1$/otrs-ticket.pl --otrs_user="user" --otrs_pass="pass" --otrs_server="server.domain.com:80" --event_id="$HOSTEVENTID$" --event_id_last="$LASTHOSTEVENTID$" --event_type="$NOTIFICATIONTYPE$" --event_date="$LONGDATETIME$" --event_host="$HOSTNAME$" --event_addr="$HOSTADDRESS$" --event_desc="$SERVICEACKAUTHOR$ $SERVICEACKCOMMENT$" --event_state="$HOSTSTATE$" --event_output="$HOSTOUTPUT$"
#
# Centreon->Configuration->Commands->Notifications->notify-otrs-ticket:
#	 $USER1$/otrs-ticket.pl --otrs_user="user" --otrs_pass="pass" --otrs_server="server.domain.com:80" --event_id="$SERVICEEVENTID$" --event_id_last="$LASTSERVICEID$" --event_type="$NOTIFICATIONTYPE$" --event_date="$LONGDATETIME$" --event_host="$HOSTALIAS$" --event_addr="$HOSTADDRESS$" --event_desc="$SERVICEDESC$" --event_state="$SERVICESTATE$" --event_output="$SERVICEOUTPUT$"

use strict;
use Socket;
use Getopt::Long;
use DBI;
use DBD::SQLite;
use SOAP::Lite;
use Log::Handler;

my $VERSION = '1.1';

# hard-code paths to prevent warning from taint mode
my $logfile = '/var/tmp/otrs-ticket.log';
my $csvfile = '/var/tmp/otrs-ticket.csv';
my $dbname = '/var/tmp/otrs-ticket.sqlite';
my $dbuser = '';
my $dbpass = '';
my $dbtable = 'TicketIDAssoc';
# set $state_on_last to 'closed successful' (for example) to close tickets
# when service returns (Centreon / Nagios passed the $LASTEVENTID$ or
# $LASTSERVICEID$ argument)
my $state_on_last = '';
my $TicketID;
my $TicketNumber;
my $ArticleID;
my %otrs_defaults = (
	'Queue' => 'UNIX',
	'PriorityID' => '3',
	'Type' => 'Incident',
	'State' => 'new',
	'CustomerUser' => 'unknown',
	'Service' => 'Infrastructure::Server::Unix/Linux',
);

# read command line options
my %opt = ();
GetOptions(\%opt, 'otrs_user=s', 'otrs_pass=s', 'otrs_server=s', 'event_id=s',
'event_id_last=s', 'event_type=s', 'event_date=s', 'event_host=s',
'event_addr=s', 'event_desc=s', 'event_state=s', 'event_output=s',
'otrs_customer=s', 'otrs_queue=s', 'otrs_priority=s', 'otrs_type=s',
'otrs_state=s', 'otrs_service=s', 'verbose');

# silently strip anything non-numeric from integer fields (where-as
# GetOptions's '=i' would throw an error)
for ( qw( event_id event_id_last ) ) { $opt{$_} =~ s/[^0-9]// if (defined $opt{$_}); }

# beautify some option names for logging, ticket text, etc.
my %event_info = (
	'EventID' => $opt{'event_id'} ||= '',
	'EventIDLast' => $opt{'event_id_last'} ||= '',
	'EventType' => $opt{'event_type'} ||= '',
	'EventDate' => $opt{'event_date'} ||= '',
	'EventHostName' => $opt{'event_host'} ||= '',
	'EventHostAddress' => $opt{'event_addr'} ||= '',
	'EventServiceDesc' => $opt{'event_desc'} ||= '',
	'EventState' => $opt{'event_state'} ||= '',
	'EventOutput' => $opt{'event_output'} ||= '',
);

if (defined $opt{'event_id'} && $opt{'event_id'} == 0 
	&& defined $opt{'event_id_last'} && $opt{'event_id_last'} > 0) {
	$opt{'event_id'} = $opt{'event_id_last'};
	$opt{'otrs_state'} = $state_on_last 
		if ($state_on_last && !$opt{'otrs_state'});
}

my $stdout = $opt{'verbose'} ? 'debug' : 'info';
my $log = Log::Handler->new();
$log->add(
	file => {
		filename => $logfile,
		maxlevel => 'debug',
		timeformat => '%Y%m%d-%H%M%S',
        },
	screen => {
		log_to   => 'STDOUT',
		maxlevel => $stdout,
		timeformat => '%Y%m%d-%H%M%S',
	},
);

$log->info("START of $0 v$VERSION script");

#
# Log the command line options to a csv file to keep a history (even if some
# arguments might be missing).
#
$log->debug("Saving event_info fields to $csvfile.");
unless (open (CSV, ">>$csvfile")) { $log->critical("Error opening ".$csvfile.": ".$!); &DoExit(1); }
unless (-s $csvfile) { for (sort keys %event_info) { print CSV '"', $_, '",'; }; print CSV "\n"; }
for (sort keys %event_info) { print CSV '"', $event_info{$_}, '",'; }; print CSV "\n";
close (CSV);

#
# Check all essential opt values and exit if some missing.
#
my @essential_opts = sort qw( otrs_user otrs_pass otrs_server event_id event_type
event_date event_host event_addr event_state event_output );

# print the whole list before exiting
for (@essential_opts) {
	$log->error("Required argument $_ not defined or empty!") 
		if (!defined $opt{$_} || $opt{$_} eq '');
}
for (@essential_opts) { &DoExit(1) if (! $opt{$_}); }

for (sort keys %opt) {
	if ($_ eq 'otrs_pass' ) { $log->debug("Argument $_ = ********") }
	else { $log->debug("Argument $_ = $opt{$_}"); }
}

#
# Open the database and create the table(s) if necessary
#
my $dsn = "DBI:SQLite:dbname=$dbname";
my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
if ($DBI::err) { $log->critical($DBI::errstr); &DoExit(1); }

$dbh->do("PRAGMA foreign_keys = ON");
$dbh->do("CREATE TABLE IF NOT EXISTS $dbtable ( 
	EventID INTEGER PRIMARY KEY, 
	TicketID INTEGER NOT NULL, 
	TicketNumber INTEGER )");
($TicketID, $TicketNumber) = $dbh->selectrow_array("SELECT TicketID, TicketNumber 
	FROM $dbtable WHERE EventID=?", undef, $opt{'event_id'});

#
# Configuration for OTRS connection and definition of available Ticket /
# Article fields (used when constructing the SOAP data).
#
my %otrs = (
	'UserLogin' => $opt{'otrs_user'},
	'Password' => $opt{'otrs_pass'},
	'URL' => 'http://'.$opt{'otrs_server'}.'/otrs/nph-genericinterface.pl/Webservice/GenericTicketConnector',
	'NameSpace' => 'http://www.otrs.org/TicketConnector/',
	'TicketID' => '',
	'TicketNumber' => '',
	'Operation' => '',
	'TicketFields' => [
		'Title',
		'QueueID',
		'Queue',
		'TypeID',
		'Type',
		'ServiceID',
		'Service',
		'SLAID',
		'SLA',
		'StateID',
		'State',
		'PriorityID',
		'Priority',
		'OwnerID',
		'Owner',
		'ResponsibleID',
		'Responsible',
		'CustomerUser',
	],
	'ArticleFields' => [ 
		'ArticleTypeID',
		'ArticleType',
		'SenderTypeID',
		'SenderType',
		'Subject',
		'Body',
		'ContentType',
		'Charset',
		'MimeType',
		'HistoryType',
		'HistoryComment',
		'AutoResponseType',
		'TimeUnit',
		'NoAgentNotify',
		'ForceNotificationToUserID',
		'ExcludeNotificationToUserID',
		'ExcludeMuteNotificationToUserID',
	],
);


#
# Define the ticket details here.
#
my %ticket;
if ($TicketID) {
	$log->info("Found EventID $opt{'event_id'} in database");
	$log->info("Updating TicketID $TicketID (TicketNumber $TicketNumber)");
	$otrs{'Operation'} = 'TicketUpdate';
	$otrs{'TicketID'} = $TicketID;
	# if we have a different state (than new) defined, then use it, otherwise leave as-is
	if (defined $opt{'otrs_state'} && $opt{'otrs_state'}) {
		$ticket{'State'} = $opt{'otrs_state'};
		$log->notice('Updating Ticket State to "'.$ticket{'State'}.'"');
	}
} else {
	$log->debug("EventID ".$opt{'event_id'}." not found in database");
	$log->info("Creating new OTRS Ticket for EventID ".$opt{'event_id'});
	$otrs{'Operation'} = 'TicketCreate';
	%ticket = (
		'Queue' => $opt{'otrs_queue'} ||= $otrs_defaults{'Queue'},
		'PriorityID' => $opt{'otrs_priority'} ||= $otrs_defaults{'PriorityID'},
		'Type' => $opt{'otrs_type'} ||= $otrs_defaults{'Type'},
		'State' => $opt{'otrs_state'} ||= $otrs_defaults{'State'},
		'Service' => $opt{'otrs_service'} ||= $otrs_defaults{'Service'},
		'DynamicField' => {
			'EventID' => $opt{'event_id'},
			'EventHostName' => $opt{'event_host'},
			'EventHostAddress' => $opt{'event_addr'},
			'EventServiceDesc' => $opt{'event_desc'},
		},
	);
}

# Common ticket fields / values for TicketUpdate or TicketCreate.
$ticket{'CustomerUser'} = $opt{'otrs_customer'} ||= $otrs_defaults{'CustomerUser'};
$ticket{'ContentType'} = 'text/plain; charset=utf8';
$ticket{'SenderType'} = 'system';
$ticket{'Title'} = "$opt{'event_type'}: $opt{'event_host'}/$opt{'event_desc'} is $opt{'event_state'}";
$ticket{'Subject'} = $ticket{'Title'};
$ticket{'Body'} = $opt{'event_output'}."\n\n";

# Append all the "event_info" fields to the ticket for reference.
for (sort keys %event_info) { $ticket{'Body'} .= "$_ = $event_info{$_}\n"; }

#
# Convert Ticket and Article data into SOAP data structure
#
my @SOAPTicketData = ();
for my $el (@{$otrs{'TicketFields'}}) {
	if ( $ticket{$el}) {
		for (split (/\n/, $ticket{$el})) {
			$log->debug("TicketData $el = $_"); }
		push @SOAPTicketData, SOAP::Data->name($el => $ticket{$el});
	}
}

my @SOAPArticleData = ();
for my $el (@{$otrs{'ArticleFields'}}) {
	if ( $ticket{$el} ) {
		for (split (/\n/, $ticket{$el})) {
			$log->debug("ArticleData $el = $_"); }
		push @SOAPArticleData, SOAP::Data->name( $el => $ticket{$el} );
	}
}

# Dynamic Fields must be created in OTRS first.
my $DynamicFieldXML;
for ( sort keys %{$ticket{'DynamicField'}} ) {
	if ( $ticket{'DynamicField'}->{$_} ) {
		$log->debug("ArticleData $_ = $ticket{'DynamicField'}->{$_}");
		$DynamicFieldXML .= '<DynamicField><Name><![CDATA['.$_.']]></Name>'
			.'<Value><![CDATA['.$ticket{'DynamicField'}->{$_}.']]></Value></DynamicField>'."\n";
	}
}

if ($opt{'otrs_server'} =~ /^([^:]*)/) {
	my $ip_nbo = inet_aton($1);
	if (!$ip_nbo) { $log->critical("Failed to resolve IP of ".$1); &DoExit(1); }
	$log->info( "OTRS Server is ".$opt{'otrs_server'}." (".inet_ntoa($ip_nbo).")" );
}

my $soap_op = $otrs{'Operation'}; $log->info("SOAP $soap_op at ".$otrs{'URL'});
my $soap_obj = SOAP::Lite->uri($otrs{'NameSpace'})->proxy($otrs{'URL'})->$soap_op(
	SOAP::Data->name('UserLogin')->value($otrs{'UserLogin'}),
    	SOAP::Data->name('Password')->value($otrs{'Password'}),
    	SOAP::Data->name('TicketID')->value($otrs{'TicketID'}),
    	SOAP::Data->name('TicketNumber')->value($otrs{'TicketNumber'}),
	SOAP::Data->name('Ticket' => \SOAP::Data->value(@SOAPTicketData)),
	SOAP::Data->name('Article' => \SOAP::Data->value(@SOAPArticleData)),
	SOAP::Data->type('xml'=> $DynamicFieldXML),
);

if ( $soap_obj->fault ) { $log->critical($soap_obj->faultcode.": ".$soap_obj->faultstring); &DoExit(1); }

$log->info("SOAP transaction successful");

# get the XML response part from the SOAP message
my $XMLResponse = $soap_obj->context()->transport()->proxy()->http_response()->content();

# deserialize response (convert it into a perl structure)
my $Deserialized = eval { SOAP::Deserializer->deserialize($XMLResponse); };

# remove all the headers and other not needed parts of the SOAP message
my $Body = $Deserialized->body();

# check if ticket was created or updated
my $Response = $Body->{'TicketCreateResponse'} ? 
	'TicketCreateResponse' : 'TicketUpdateResponse';

if (defined $Body->{$Response}->{Error}) {
	$log->error("Error found in $Response");
	$log->error($Body->{$Response}->{Error}->{ErrorCode}." = ".$Body->{$Response}->{Error}->{ErrorMessage});
	&DoExit(1);
}

$TicketID = $Body->{$Response}->{TicketID};
$TicketNumber = $Body->{$Response}->{TicketNumber};
$ArticleID = $Body->{$Response}->{ArticleID};

my $ticket_sum = "TicketID $TicketID (TicketNumber $TicketNumber, ArticleID $ArticleID)";

if ($Response eq 'TicketUpdateResponse') { $log->info("Updated $ticket_sum"); }
else {
	$log->info("Created $ticket_sum");
	$log->info("Adding TicketID $TicketID and EventID $opt{'event_id'} to $dbname");
	my $sth = $dbh->prepare("INSERT INTO $dbtable VALUES ( ?, ?, ? )");
	$sth->execute($opt{'event_id'}, $TicketID, $TicketNumber);
}

&DoExit(0);

sub DoExit {
	my ($err) = @_;
	$log->info("END of $0 v$VERSION script");
	exit $err;
}

