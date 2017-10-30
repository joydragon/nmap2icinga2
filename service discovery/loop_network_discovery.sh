#!/bin/bash
OUTPUT=output.log
BASH_DISCOVERY="./network_discovery.sh"
CFG_DIR="/etc/icinga2/conf.d/autogen/"
BACKUP_DIR="./backup_cfg/"

RED_10="10.0.0.1/24"
ARCHIVO_RED_10=nmap_red_10_0_0_1.txt
FINAL_ARCHIVO_RED_10=red_10_0_0.conf

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
	TMP_ARCHIVO_RED="temp_$3"
	FINAL_ARCHIVO_RED=$3

	echo "Starting the scan loop for $1" >> $OUTPUT
	#echo "/bin/bash \"$BASH_DISCOVERY\" -a \"$RED\" -c \"$TMP_ARCHIVO_RED\" -m \"$ARCHIVO_RED\" -o \"$OUTPUT\""
	/bin/bash "$BASH_DISCOVERY" -a "$RED" -c "$TMP_ARCHIVO_RED" -m "$ARCHIVO_RED" -o "$OUTPUT"
	# Checking the differences
	if [ -f "${CFG_DIR}${FINAL_ARCHIVO_RED}" ]; then
		echo "Checking the differences..." >> $OUTPUT
		diff -DVERSION1 "${CFG_DIR}${FINAL_ARCHIVO_RED}" "$TMP_ARCHIVO_RED" > temp1.txt
		# Removing the conflicting part from the new output
		echo "Removing the tags and the conflicts" >> $OUTPUT
		sed '/#else/,/#endif/d' temp1.txt | sed '/#/d' > temp2.txt
		# Renaming the modified file
		echo "Renaming the output file" >> $OUTPUT
		mv temp2.txt $FINAL_ARCHIVO_RED
		
		# Deleting the temp files
		rm -f ./temp* 2>&1 > /dev/null
	else
		echo "There's no similar file on the current configuration set." >> $OUTPUT
		echo "Skipping the diff for $FINAL_ARCHIVO_RED" >> $OUTPUT
		mv "$TMP_ARCHIVO_RED" "$FINAL_ARCHIVO_RED"
	fi

	return 0
}

# Here is where you can add all the scan_it lines that you want
scan_it $RED_10 $ARCHIVO_RED_10 $FINAL_ARCHIVO_RED_10
