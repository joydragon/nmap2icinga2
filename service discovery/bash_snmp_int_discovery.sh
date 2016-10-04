# NEED TO GET THE FIRST ARGUMENT AS THE OBJECTIVE IP
# Using the default SNMP comunity, and SNMP version 2c
OUTPUT="tmp_snmpwalk.log"
SNMPWALK=`snmpwalk -c public -v 2c -t 0.1 $1 ifDescr 2>/dev/null > $OUTPUT`
STATUS=$?

# Check if exits normally
if [[ $STATUS != "0" ]]; then
        exit
fi

# Obtain all the info, and print it as needed for the main AWK (with doble colon separators)
# Ej.
#    iface_1;;GigabitEthernet1/1/1

sed -re "s/^.+ifDescr\.([0-9]+)\s+=.*:\s+(.*)$/\1;;\2/" $OUTPUT