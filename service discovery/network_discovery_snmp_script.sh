# GET THE FIRST ARGUMENT AS IP
OUTPUT="./tmp_snmpwalk.log"
SNMPWALK=`snmpwalk -c minrel -v 2c -t 0.1 $1 ifDescr 2>/dev/null > $OUTPUT`
STATUS=$?

if [[ $STATUS != "0" ]]; then
        exit
fi

sed -re "s/^.+ifDescr\.([0-9]+)\s+=.*:\s+(.*)$/\1;;\2/" $OUTPUT

exit
RES=`sed -re "s/^.+ifDescr\.([0-9]+)\s+=.*:\s+(.*)$/\1;;\2/" $OUTPUT`
printf "%s\n" $RES
