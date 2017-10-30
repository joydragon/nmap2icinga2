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

Here's the explanation of what does each file do:
* *network_discovery.sh*: This is the main file for the scanning process. Generates a the nmap scan and calls the AWK programm file for the translation to the final Icinga2 configuration.
* *network_discovery_awk_translator.awk*: This is the file that generates the translation from the nmap grepable output to an actual Icinga2 configuration file. Needs the snmp script if the SNMP service is detected on a target.
* *network_discovery_snmp_script.sh*: This is the file that executes snmpwalk to the detected target's service and generates the output for the AWK translator.
* *loop_network_discovery.sh*: This is the file that creates the scan loops on the target networks, also creates a backup of the current configuration (just in case)
