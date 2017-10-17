# nmap2icinga2
This is a script to make the bulk import of a Nmap grepable output to the Icinga2 hosts definition

You can learn a bit more of what I was thinking about when I created this scripts on the following link (in Spanish): https://blog.joydragon.info/2016/08/07/como-usar-icinga2-para-monitorear-la-red/

## Port Discovery

Using only the port discovery capabilities of nmap (without the -sV flag) and the grepable flag (-oG), we can define the host for icinga2 with just one script.

## Service Discovery

If we now use the port discovery capabilities of nmap (the -sV flag) and the grepable flag (-oG), we can define the host for icinga2 with one script also, but changing the definition of the services.

## IP-Range Monitor

This is the new script that should monitor an IP or a Range of IPs for any changes on the current status stored on the Icinga2 configuration.

This scripts need access to the Icinga2 CLI https://www.icinga.com/docs/icinga2/latest/doc/11-cli-commands/
