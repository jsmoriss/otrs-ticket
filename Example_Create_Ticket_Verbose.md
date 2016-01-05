# Introduction #

An example screen output when creating an OTRS ticket with the --verbose command-line argument.

# Details #

```
$ ./otrs-ticket.pl --verbose \
        --otrs_user="centreon" \
        --otrs_pass="password" \
        --otrs_server="support.DOMAINNAME.com:80" \
        --otrs_customer="unknown" \
        --problem_id="1234" \
        --event_type="PROBLEM" \
        --event_date="Fri Oct 13 00:30:28 CDT 2000" \
        --event_host="TEST-TICKET-01" \
        --event_addr="127.0.0.1" \
        --event_desc="$ $" \
        --event_state="DOWN" \
        --event_output="Host Unreachable"

20121109-141217 [INFO] START of ./otrs-ticket.pl v1.2 script
20121109-141217 [DEBUG] Saving event_info fields to /var/tmp/otrs-ticket.csv.
20121109-141217 [DEBUG] Argument event_addr = 127.0.0.1
20121109-141217 [DEBUG] Argument event_date = Fri Oct 13 00:30:28 CDT 2000
20121109-141217 [DEBUG] Argument event_desc = 
20121109-141217 [DEBUG] Argument event_host = TEST-TICKET-01
20121109-141217 [DEBUG] Argument event_output = Host Unreachable
20121109-141217 [DEBUG] Argument event_state = DOWN
20121109-141217 [DEBUG] Argument event_type = PROBLEM
20121109-141217 [DEBUG] Argument otrs_customer = unknown
20121109-141217 [DEBUG] Argument otrs_pass = ********
20121109-141217 [DEBUG] Argument otrs_server = support.DOMAINNAME.com:80
20121109-141217 [DEBUG] Argument otrs_user = centreon
20121109-141217 [DEBUG] Argument problem_id = 1234
20121109-141217 [DEBUG] Argument problem_id_last = 0
20121109-141217 [DEBUG] Argument verbose = 1
20121109-141217 [DEBUG] ProblemID 1234 not found in database
20121109-141217 [INFO] Creating new OTRS Ticket for ProblemID 1234
20121109-141217 [DEBUG] TicketData Title = PROBLEM: TEST-TICKET-01 is DOWN
20121109-141217 [DEBUG] TicketData Queue = UNIX
20121109-141217 [DEBUG] TicketData Type = Incident
20121109-141217 [DEBUG] TicketData Service = Infrastructure::Server::Unix/Linux
20121109-141217 [DEBUG] TicketData State = new
20121109-141217 [DEBUG] TicketData PriorityID = 3
20121109-141217 [DEBUG] TicketData CustomerUser = unknown
20121109-141217 [DEBUG] ArticleData SenderType = system
20121109-141217 [DEBUG] ArticleData Subject = PROBLEM: TEST-TICKET-01 is DOWN
20121109-141217 [DEBUG] ArticleData Body = Host Unreachable
20121109-141217 [DEBUG] ArticleData Body = 
20121109-141217 [DEBUG] ArticleData Body = EventDate = Fri Oct 13 00:30:28 CDT 2000
20121109-141217 [DEBUG] ArticleData Body = EventHostAddress = 127.0.0.1
20121109-141217 [DEBUG] ArticleData Body = EventHostName = TEST-TICKET-01
20121109-141217 [DEBUG] ArticleData Body = EventOutput = Host Unreachable
20121109-141217 [DEBUG] ArticleData Body = EventServiceDesc = 
20121109-141217 [DEBUG] ArticleData Body = EventState = DOWN
20121109-141217 [DEBUG] ArticleData Body = EventType = PROBLEM
20121109-141217 [DEBUG] ArticleData Body = ProblemID = 1234
20121109-141217 [DEBUG] ArticleData Body = ProblemIDLast = 0
20121109-141217 [DEBUG] ArticleData ContentType = text/plain; charset=utf8
20121109-141217 [DEBUG] ArticleData HostAddress = 127.0.0.1
20121109-141217 [DEBUG] ArticleData HostName = TEST-TICKET-01
20121109-141217 [DEBUG] ArticleData ProblemID = 1234
20121109-141217 [INFO] OTRS Server is support.DOMAINNAME.com:80 (172.20.244.71)
20121109-141217 [INFO] SOAP TicketCreate at http://support.DOMAINNAME.com:80/otrs/nph-genericinterface.pl/Webservice/GenericTicketConnector
20121109-141217 [INFO] SOAP transaction successful
20121109-141217 [INFO] Created TicketID 954 (TicketNumber 2012110910000271, ArticleID 5174)
20121109-141217 [INFO] Adding TicketID 954 and ProblemID 1234 to /var/tmp/otrs-ticket.sqlite
20121109-141217 [INFO] END of ./otrs-ticket.pl v1.2 script
```