# Introduction #

OTRS configuration options for the otrs-ticket.pl script.

# Details #

  1. The [GenericTicketConnector.yml](http://source.otrs.org/viewvc.cgi/otrs/development/webservices/GenericTicketConnector.yml?view=co) must be installed in OTRS -> Admin -> Web Services.
  1. A user login (aka "Agent") must be created in OTRS for the otrs-ticket.pl script (for example: firstname = Centreon, lastname = Monitoring, username = centreon). Use the --otrs\_user, --otrs\_pass, and --otrs\_server command-line options to define the authentication credentials for otrs-ticket.pl.
  1. An OTRS queue must be created. The default queue name is "UNIX", as defined in the %otrs\_defaults variable within the otrs-ticket.pl code, but can be over-ridden on the command-line with the --otrs\_queue parameter. I would recommend that the "Follow up Option" in the OTRS queue be set to "possible" to allow service restoration notifications to update the ticket, even after it has been closed. The otrs-ticket.pl script can also manage any of the other follow-up conditions.
  1. Some of the command-line information passed to otrs-ticket.pl is saved as DynamicFields. The following four DynamicFields must be created in OTRS:
```
ProblemID
HostName
HostAddress
ServiceDesc
```
  1. A new State named "recovered" should be created (State type = open, Comment = Service has recovered.). The State type can be "open" or "closed" depending on your preference when the service is restored. If you would rather not change states on a RECOVERY event, modify the %otrs\_states variable in the otrs-ticket.pl code (removing or adding elements as necessary).
  1. If you use the --otrs\_customer command-line option, don't forget to create the appropriate customer usernames in OTRS as well.
  1. If you use the --otrs\_service command-line option, don't forget to create the appropriate services in OTRS first. The default OTRS Service, as defined in the %otrs\_defaults variable, is "Infrastructure::Server::Unix/Linux". You might want to change the default, or create those three Service names in OTRS.

