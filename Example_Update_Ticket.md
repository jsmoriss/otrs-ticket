# Introduction #

An example screen output when updating an OTRS ticket (without the --verbose command-line argument).

# Details #

```
20121109-141248 [INFO] START of ./otrs-ticket.pl v1.2 script
20121109-141248 [INFO] Found ProblemID 1234 in database
20121109-141248 [INFO] Updating TicketID 954 (TicketNumber 2012110910000271)
20121109-141248 [NOTICE] Updating Ticket State to "recovered"
20121109-141248 [INFO] OTRS Server is support.DOMAINNAME.com:80 (172.20.244.71)
20121109-141248 [INFO] SOAP TicketUpdate at http://support.DOMAINNAME.com:80/otrs/nph-genericinterface.pl/Webservice/GenericTicketConnector
20121109-141248 [INFO] SOAP transaction successful
20121109-141248 [INFO] Updated TicketID 954 (TicketNumber 2012110910000271, ArticleID 5175)
20121109-141248 [INFO] END of ./otrs-ticket.pl v1.2 script
```