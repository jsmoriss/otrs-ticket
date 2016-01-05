# Introduction #

Centreon (and Nagios) configuration for the otrs-ticket.pl script.

# Details #

The otrs-ticket.pl script should be located in the /usr/local/nagios/libexec/ folder (for example) on the main Centreon and it's pollers. The uses uses the DBI, DBD::SQLite, SOAP::Lite, and Log::Handler modules. All of these perl modules must be installed on the Centreon pollers as well.

The otr-ticket.pl script outputs some basic informational messages to stdout. The script can also be called with the --verbose option to get additional information printed on stdout. It maintains three files under /var/tmp/. Since the script uses perl's taint mode, the location of these three files had to be hard-coded (or put in a configuration file - which I decided to avoid using).

  1. /var/tmp/otrs-ticket.log : Debug-level output that can be used to track all submitted information, the script's interpretation of them, and it's actions.
  1. /var/tmp/otrs-ticket.csv : All submitted command-line options in a CSV file format. This could be used to review all notifications from Centreon to OTRS.
  1. /var/tmp/otrs-ticket.sqlite : An SQLite database file used to track Centreon Problem IDs and their associated OTRS Ticket IDs.

## Host Notification ##

Centreon->Configuration->Commands->Notifications->host-notify-otrs-ticket

```
$USER1$/otrs-ticket.pl --otrs_user="user" --otrs_pass="pass" --otrs_server="server.domain.com:80" --problem_id="$HOSTPROBLEMID$" --problem_id_last="$LASTHOSTPROBLEMID$" --event_type="$NOTIFICATIONTYPE$" --event_date="$LONGDATETIME$" --event_host="$HOSTNAME$" --event_addr="$HOSTADDRESS$" --event_desc="$SERVICEACKAUTHOR$ $SERVICEACKCOMMENT$" --event_state="$HOSTSTATE$" --event_output="$HOSTOUTPUT$"
```

## Service Notification ##

Centreon->Configuration->Commands->Notifications->notify-otrs-ticket

```
$USER1$/otrs-ticket.pl --otrs_user="user" --otrs_pass="pass" --otrs_server="server.domain.com:80" --problem_id="$SERVICEPROBLEMID$" --problem_id_last="$LASTSERVICEPROBLEMID$" --event_type="$NOTIFICATIONTYPE$" --event_date="$LONGDATETIME$" --event_host="$HOSTALIAS$" --event_addr="$HOSTADDRESS$" --event_desc="$SERVICEDESC$" --event_state="$SERVICESTATE$" --event_output="$SERVICEOUTPUT$"
```