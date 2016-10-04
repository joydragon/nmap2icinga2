#Service Discovery

Here are the scripts for the second part, the service discovery.

First you must start with the nmap command using the **-oG** and **-sV** flag:
```
nmap -sT -sV -O -oG <file_output> <IP_range>
```
Then using the awk script you can set properly the information provided by nmap and parse it into the host configuration used by Icinga2
```
egrep -ve "^#" <file_output> | awk 'NR % 2 == 0' | awk -f <awk_file>
```

Finally we go on a snmpwalk using the default credentials and there we can check the current load of our switch interfaces.

All of that on a simple bash script called comando_cron.sh that as you can see, it's meant to be set up as a cron job
