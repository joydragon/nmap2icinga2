#!/bin/bash
AWK_FILE="./network_discovery_awk_translator.awk"
DNS_SERVER=8.8.8.8

## Function helpers
Usage() {
cat << EOF
Usage:
	bash network_discovery.sh [Parameters] -a <ADDRESS>

Required parameters:
  -a ADDRESS TO SCAN (Can be a range in CIDR format)

Optional parameters:
  -h Help
  -c CONFIGURATION FILE (default: new_network.conf)
  -o SCRIPT OUTPUT (default: output.log)
  -m NMAP GREPABLE OUTPUT (default: nmap_output.log)
EOF
}

Help() {
  Usage;
  exit 0;
}

if [ $# -lt 1 ]; then
	echo "ERROR: There's no enough parameters"
	echo ""
	Help
	exit 1
fi

## Main
while getopts a:c:hm:o: opt
do
  case "$opt" in
    a) NETWORK_ADDRESS=$OPTARG ;; # required
    c) CONFIGURATION_FILE=$OPTARG ;;
    m) NMAP_OUTPUT_FILE=$OPTARG ;;
    o) OUTPUT=$OPTARG ;;
    h) Help ;;
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Error ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Error ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Error ;;
  esac
done

shift $((OPTIND - 1))

if [ ! "$NETWORK_ADDRESS" ]; then
	echo "ERROR: Address not defined"
	exit
fi

if [ ! "$CONFIGURATION_FILE" ];then
	CONFIGURATION_FILE="./new_network.conf"
fi

if [ ! "$OUTPUT" ];then
	OUTPUT="./output.log"
fi

if [ ! "$NMAP_OUTPUT_FILE" ];then
	NMAP_OUTPUT_FILE="./nmap_output.log"
fi

TMP_OUTPUT_CONF="./temp_output.conf"

echo "" >> $OUTPUT
echo "" >> $OUTPUT
echo "Starting with $NETWORK_ADDRESS" >> $OUTPUT
if [ -f $NMAP_OUTPUT_FILE ]; then
echo "Deleting previous file ..." >> $OUTPUT
    rm -f $NMAP_OUTPUT_FILE
fi
echo "Starting scan for $NETWORK_ADDRESS ..." >> $OUTPUT
sudo nmap $NETWORK_ADDRESS -R --dns-servers $DNS_SERVER -O -f -sS -sV -oG "$NMAP_OUTPUT_FILE" >> $OUTPUT 2>&1
echo "Finished scan for $NETWORK_ADDRESS" >> $OUTPUT

FILTERED_NMAP=`egrep -ve "^#" $NMAP_OUTPUT_FILE`
if [[ -n "$FILTERED_NMAP" ]]; then
	echo "Translating to hosts.cfg ..." >> $OUTPUT
	egrep -ve "^#" $NMAP_OUTPUT_FILE | awk 'NR % 2 == 0' | awk -f "$AWK_FILE" -v "output_filename=$TMP_OUTPUT_CONF" >> $OUTPUT
	echo "Finished the translation to hosts.cfg ..." >> $OUTPUT

	mv "$TMP_OUTPUT_CONF" "$CONFIGURATION_FILE"

	rm -f ./tmp_snmpwalk.log 
	#rm -f ./processed.conf
else
	echo "There's nothing to configure, there are no hosts to check." >> $OUTPUT
	echo "Exiting." >> $OUTPUT
fi
exit
