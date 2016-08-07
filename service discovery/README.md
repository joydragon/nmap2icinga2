#Service Discovery

Here are the scripts for the seconf part, the service discovery.

First you must start with the nmap command using the **-oG** and **-sV** flag:
```
nmap -sT -sV -O -oG <file_output> <IP_range>
```
Then using the awk script you can set properly the information provided by nmap and parse it into the host configuration used by Icinga2
```
egrep -ve "^#" <file_output> | awk 'NR % 2 == 0' | awk -f <awk_file>
```

And voila!
