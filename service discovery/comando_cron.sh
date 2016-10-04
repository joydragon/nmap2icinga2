#!/bin/bash
AWK_FILE=awk_process.awk ## This is the AWK companion file
OUTPUT=output.log
CFG_DIR=/etc/icinga2/conf.d/target/
BACKUP_DIR=/tmp/backup_cfg/
DNS_SERVER=8.8.8.8 ## Use your own DNS server here

# You can define multiple networks to scan, and configuring all the necesary parameters
RED_10="10.10.255.1/24"
ARCHIVO_RED_10=nmap_red_10_10_255_1.txt
FINAL_ARCHIVO_RED_10=red_10_10_255.conf

# Command starts now
echo "" >> $OUTPUT
echo "" >> $OUTPUT
date >> $OUTPUT
echo "" >> $OUTPUT
echo "" >> $OUTPUT

# Inicio de backup
echo "Generating backup of the configuration files ..." >> $OUTPUT
zip ${BACKUP_DIR}icinga_minrel_`date +%Y%m%d-%H%M%S`.zip ${CFG_DIR}red_* >> $OUTPUT
echo "Done." >> $OUTPUT

function scan_it {
	# Parsing te parameters to the variables
	RED=$1
	ARCHIVO_RED=$2
	FINAL_ARCHIVO_RED=$3

	echo "" >> $OUTPUT
	echo "" >> $OUTPUT
	echo "Starting with $RED" >> $OUTPUT
	if [ -f $ARCHIVO_RED ]; then
	echo "Deleting previous file ..." >> $OUTPUT
	    rm -f $ARCHIVO_RED
	fi
	echo "Starting scan for $RED ..." >> $OUTPUT
	sudo nmap $RED -R --dns-servers $DNS_SERVER -O -f -sS -sV -oG $ARCHIVO_RED >> $OUTPUT 2>&1
	echo "Finished scan for $RED_10" >> $OUTPUT
	echo "Translating to hosts.cfg ..." >> $OUTPUT
	# ./nmap2icinga.pl $ARCHIVO_RED_10 >> $OUTPUT 2>&1
	egrep -ve "^#" ${ARCHIVO_RED} | awk 'NR % 2 == 0' | awk -f $AWK_FILE >> $OUTPUT
	
	# Checking the differences
	echo "Checking the differences..." >> $OUTPUT
	diff -DVERSION1 ${CFG_DIR}${FINAL_ARCHIVO_RED} processed.conf > temp1.txt
	# Removing the conflicting part from the new output
	echo "Removing the tags and the conflicts" >> $OUTPUT
	sed '/#else/,/#endif/d' temp1.txt | sed '/#/d' > temp2.txt
	# Renaming the modified file
	echo "Renaming the output file" >> $OUTPUT
	mv temp2.txt $FINAL_ARCHIVO_RED
	
	# Deleting the temp files
	rm ./temp* 2>&1 > /dev/null
	rm ./tmp_snmpwalk.log
	rm ./processed.conf
}

scan_it $RED_10 $ARCHIVO_RED_10 $FINAL_ARCHIVO_RED_10

exit
# Still not ready for this part

echo "Moving the new configuration to the apropriate location." >> $OUTPUT
mv -f red* $CFG_DIR >> $OUTPUT
echo "Done moving." >> $OUTPUT

sudo service restart icinga2
