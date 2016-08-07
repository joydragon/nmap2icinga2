#Port Discovery
Here are the basic scripts for port discovery.

First you must start with the nmap command using at least the -oG flag:
nmap -sT -O -oG <file_output> <IP_range>

Then using the perl or awk scripts you can use the information provided by nmap and parse it into the host configuration used by Icinga2
perl nmap2icinga2.pl <file_output>
egrep -ve "^#" <file_output> | awk 'NR % 2 == 0' | awk -f <awk_file>

And voila!
