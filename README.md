# nmap2icinga2
This is a script to make the bulk import of a Nmap grepable output to the Icinga2 hosts definition

## Port Discovery

We have now only the port discovery part.

Using only the port discovery capabilities of nmap (without the -sV flag) and the grepable flag (-oG), we can define the host for icinga2 with just one script.
