#!/bin/bash

# This script lets you generate a basic report on your desired configuration changes on "real time"
# This script is meant to be used as one of the checks for the Icinga2 platform, you could add it as a "nagios plugin", or simply read the $MAIN_OUTPUT file afterwards

while [[ $# -gt 0 ]]
        do
        case "$1" in
                -w|--warning)
                shift
                warning=$1
        ;;
                -H|-I)
                shift
                IP=$1
        ;;
                -c|--critical)
                shift
                critical=$1
        ;;
        esac
        shift
done

TYPE=""
MAIN_OUTPUT="bash_output.log"
LOG_OUTPUT="nmap_output.log"
ARCHIVO_OUTPUT="nmap_output.xml"

if [[ -z $IP ]]; then
        echo "ERROR: There's no IP definition" >> $MAIN_OUTPUT
fi

# Revisar si la IP es valida, o si es un rango valido
regex="^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
CHECK=$(echo $IP | egrep $regex)

if [[ $? -eq 0 ]]
then
        TYPE="IP"
else
        regex="^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/([0-2]?[0-9]|3[0-2])$"
        CHECK=$(echo $IP | egrep $regex)
        if [[ $? -eq 0 ]]
        then
                TYPE="RANGE"
        else
                echo "ERROR: IP not valid" >> $MAIN_OUTPUT
                exit 1
        fi
fi

function check_if_ip_configured(){
        local IP=$1
        local TMP_P1="p1.tmp"
        local TMP_P2="p2.tmp"

        if [[ -z $IP ]]; then
                echo "ERROR: No IP is defined" >> $MAIN_OUTPUT
                return 1
        fi

        OUT=`xmlstarlet sel -t -m "/nmaprun/host/address[@addr='"$IP"']" -v "@addr" $ARCHIVO_OUTPUT`

        if [[ -n $OUT ]]; then
                # Revisar si es que esta la IP en la configuracion actual
                IS_CONF=`sudo icinga2 object list --name "$IP" --type "Host" | grep ports | sed -e "s/.*\[//" -e "s/\]//" -e "s/ //g" -e "s/\"//g" | tr "," "\n"`

                if [[ -n $IS_CONF ]]; then
                        # Si la IP esta arriba y se tiene en la configuracion se sacan los puertos
                        sudo icinga2 object list --name "$IP" --type "Host" | grep ports  | sed -e "s/.*\[//" -e "s/\]//" -e "s/ //g" -e "s/\"//g" | tr "," "\n" > $TMP_P1
                        xmlstarlet sel -t -m "/nmaprun/host[address/@addr='"$IP"']" -v "ports/port/@portid" $ARCHIVO_OUTPUT > $TMP_P2

                        MISSING_PORTS=`diff $TMP_P1 $TMP_P2 | grep "^<" | sed -e "s/^<\s*//"`
                        NEW_PORTS=`diff $TMP_P1 $TMP_P2 | grep "^>" | sed -e "s/^>\s*//"`

                        rm $TMP_P1 $TMP_P2

                        if [[ -z $MISSING_PORTS && -z $NEW_PORTS ]]; then
                                echo "CONGRATULATIONS! The IP $IP is correctly monitored" >> $MAIN_OUTPUT
                                return 0
                        elif [[ -z $NEW_PORTS ]]; then
                                echo "You have ports that are now down for the IP: $IP" >> $MAIN_OUTPUT
                                echo "$MISSING_PORTS" >> $MAIN_OUTPUT
                        elif [[ -z $MISSING_PORTS ]]; then
                                echo "You have ports that are new for the IP: $IP" >> $MAIN_OUTPUT
                                echo "$NEW_PORTS" >> $MAIN_OUTPUT
                        else
                                echo "You have ports that are now down for the IP: $IP" >> $MAIN_OUTPUT
                                echo "$MISSING_PORTS" >> $MAIN_OUTPUT
                                echo "You have ports that are new for the IP: $IP" >> $MAIN_OUTPUT
                                echo "$NEW_PORTS" >> $MAIN_OUTPUT
                        fi
                else
                        # Si la IP no esta arriba todos los puertos son nuevos:
                        NEW_PORTS=`xmlstarlet sel -t -m "/nmaprun/host[address/@addr='"$IP"']" -v "ports/port/@portid" nmap_output.xml`
                        echo "This server is now UP!" >> $MAIN_OUTPUT
                        echo "$IP" >> $MAIN_OUTPUT
                        echo "You have ports that are new for the IP: $IP" >> $MAIN_OUTPUT
                        echo "$NEW_PORTS" >> $MAIN_OUTPUT
                        return 3
                fi
        else
                echo "ERROR: The IP $IP is DOWN" >> $MAIN_OUTPUT
                return 1
        fi
        return 2
}

echo "Starting now: "$(date "+%Y-%m-%d %H:%M:%S") >> $MAIN_OUTPUT

# Revisar si la IP esta arriba
if [[ $TYPE == "IP" ]]; then
        echo "Starting with a IP scan" >> $MAIN_OUTPUT
        echo "IP: $IP" >> $MAIN_OUTPUT
        sudo nmap $IP -f -sS -Pn -oX $ARCHIVO_OUTPUT >> $LOG_OUTPUT 2>&1
        check_if_ip_configured $IP
        stat=$?
        if [[ $stat -eq 0 ]];then
                msg="OK - IP is correctly configured."
        elif [[ $stat -eq 1 ]];then
                msg="WARNING - The server on that IP is DOWN."
        elif [[ $stat -eq 2 ]];then
                msg="WARNING - There's new port configuration for the IP."
        elif [[ $stat -eq 3 ]];then
                msg="CRITICAL - There's new server on that IP."
        fi

elif [[ $TYPE == "RANGE" ]]; then
        echo "Starting with a RANGE scan" >> $MAIN_OUTPUT
        echo "RANGE: $IP" >> $MAIN_OUTPUT
        sudo nmap $IP -f -sS -Pn -oX $ARCHIVO_OUTPUT >> $LOG_OUTPUT 2>&1
        IP_LIST=`nmap -n -sL $IP | grep -e "Nmap scan report" | sed -e "s/Nmap scan report for //"`
        gstat=0
        for i in $IP_LIST; do
                check_if_ip_configured $i
                stat=$?
                if [[ $stat -eq 0 && $gstat -eq 0 ]];then
                        msg="OK - Everything is correctly configured."
                elif [[ $stat -eq 1 && $gstat -lt 1 ]];then
                        gstat=1
                        msg="WARNING - There's a server that is now DOWN."
                elif [[ $stat -eq 2 && $gstat -lt 2 ]];then
                        gstat=2
                        msg="WARNING - There's new port configuration for one or more IPs."
                elif [[ $stat -eq 3 ]];then
                        gstat=
                        msg="CRITICAL - There's new server on that IP."
                fi
        done
fi

echo "Deleting other output files" >> $MAIN_OUTPUT
rm -rf $ARCHIVO_OUTPUT $LOG_OUTPUT 2>/dev/null

echo "" >> $MAIN_OUTPUT

echo $msg
exit $stat
