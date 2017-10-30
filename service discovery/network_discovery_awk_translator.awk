BEGIN {FS="\t"}
{
	ICINGA2 = 1;
	#output_filename="./processed.conf";
	SNMP_SCRIPT="./network_discovery_snmp_script.sh"

	# Here is the Host information
	split($1,hosts," ");
	# hosts[2]	# Host Address
	# hosts[3]	# Host Name (if any)
	if( hosts[3] == "()" || hosts[3] == "(rfc1918-ignorant.gov.cl)" )
	{
		hosts[3] = hosts[2];
	}
	gsub(/(\(|\))/,"", hosts[3]);

	# Icinga2 output for host
	if ( ICINGA2 ) {
		print "object Host \"" hosts[2] "\" {" > output_filename
		print "\timport \"generic-host\"" > output_filename
		print "" > output_filename
		print "\taddress = \"" hosts[2] "\"" > output_filename
		print "\tdisplay_name = \"" hosts[3] "\"" > output_filename
		print "" > output_filename
	}

	# Here shpuld be the OS information
	if($4 ~ /OS:/){split($4,oss,": ");os = oss[2]}
	else{ os = "Default guess" }
	# oss[2]	# Os name resolution (if any)
	if (os ~ /Microsoft/) { os_short = "Windows" }
	else if (os ~ /Linux/) { os_short = "Linux" }
	else if (os ~ /BSD/) { os_short = "BSD" }
	else if (os ~ /Cisco/) { os_short = "Switch" }
	else if (os ~ /Juniper/) { os_short = "Firewall" }
	else if (os ~ /Palo Alto/) { os_short = "Firewall" }
	else if (os ~ /VxWorks/) { os_short = "Storage" }
	else if (os ~ /Dell/) { os_short = "Storage" }
	else if (os ~ /HP/) { os_short = "Storage" }
	else if (os ~ /APC/) { os_short = "UPS" }
	else { os_short = "default"}

	# Icinga2 output for OS
	if ( ICINGA2 ){
		print "\tvars.os = \"" os_short "\"" > output_filename
		print "\tvars.os_full = \"" os "\"" > output_filename
		print "" > output_filename;
	}

	# If Switch then do a snmpwalk and check for results
	delete switch_int
	if ( os_short ~ /Switch/ ) {
		#system("bash_snmp_int_discovery.sh " hosts[2])
		#cmd = "./network_discovery_snmp_script.sh"  hosts[2]
		cmd = SNMP_SCRIPT " " hosts[2]
		while ( ( cmd | getline result ) > 0 ) {
			split(result,temp,";;")
			switch_int[ temp[1] ] = temp[2]
			print "\tvars.snmp[\"iface_" temp[1] "\"] = { " > output_filename
			print "\t\tsnmp_interface = \"" temp[2] "\"" > output_filename
			print "\t}" > output_filename
			print "" > output_filename
		} 
		close(cmd)
	}

	# Start processing the ports for the node
	if( index($2, "," )  == 0 ) { delete arr_ports; arr_ports[1] = $2 }
	else { split($2,arr_ports,",") }
	gsub(/Ports:/,"",arr_ports[1]);
	ports=""
	groups=""
	known=""
	unknown="" 
	for( i=1; i <= length(arr_ports); i++)
	{
		# Trimming the information
		gsub(/^[ \t]+/,"",arr_ports[i]);
		gsub(/[ \t]+$/,"",arr_ports[i]);
		print arr_ports[i]

		# Spliting the port information on /
		split(arr_ports[i],info,"/");
		# info[1] # Port Number
		# info[2] # Port Status (open, closed, filtered)
		# info[3] # Port protocol (tcp)
		# info[4] # Port Owner
		# info[5] # Port Service (http, dns)
		# info[6] # Port RPC Info
		# info[7] # Port Service Version

		# If the port is open, process it
		if(info[2] ~ /open/)
		{
			# Add it to the port list
			ports = ports "\""info[1]"\", "
			
			# Remove the colon : and semi colon ; from the description, because we use it for separation
			gsub(/(:|;)/,"",info[7]);

			# If it has the question mark ?, on the service nmap is not sure
			if ( info[5] ~ /\?/ ){unknown = unknown info[1]":"info[5]";" }
			else { known = known info[1]":"info[5]":"info[7]";" }

			if ( info[5] ~ /http/ && info[5] !~ /ncacn_http/ ) {
				if ( index( groups, "web" ) == 0 ) { groups = groups "\"web\", " }
				if ( ICINGA2 ) {
					if( info[5] ~ /ssl/ || info[5] ~ /https/ ){ print "\tvars.http_vhosts[\"https_" info[1] "\"] = {" > output_filename; }
					else { print "\tvars.http_vhosts[\"http_" info[1] "\"] = {" > output_filename; }

					print "\t\thttp_port = \"" info[1] "\"" > output_filename;
					print "\t\thttp_uri = \"/\"" > output_filename;

					if( info[5] ~ /ssl/ || info[5] ~ /https/ ){ print "\t\thttp_ssl = 1" > output_filename; }

					print "\t}" > output_filename;
					print "" > output_filename;
				}
			}
			else if ( info[5] ~ /ssh/ ) {
				if ( index( groups, "ssh" ) == 0 ) { groups = groups "\"ssh\", " }
				if ( ICINGA2 ) {
					print "\tvars.sshd[\"ssh_" info[1] "\"] = {" > output_filename;
					print "\t\tssh_port = \"" info[1] "\"" > output_filename;
					print "\t}" > output_filename;
					print "" > output_filename;
				}
			}
			else if ( info[5] ~ /ftp/ ) {
				if ( index( groups, "ftp" ) == 0 ) { groups = groups "\"ftp\", " }
				if ( ICINGA2 ) {
					print "\tvars.ftpd[\"ftp_" info[1] "\"] = {" > output_filename;
					print "\t\tftp_port = \"" info[1] "\"" > output_filename;
					print "\t}" > output_filename;
					print "" > output_filename;
				}
			}
			else if ( info[5] ~ /smtp/ ) {
				if ( ICINGA2 ) {
					print "\tvars.smtpd[\"smtp_" info[1] "\"] = {" > output_filename;
					print "\t\tsmtp_port = \"" info[1] "\"" > output_filename;
					print "\t}" > output_filename;
					print "" > output_filename;
				}
			}
			else if ( info[5] ~ /telnet/ ) {
				if ( ICINGA2 ) {
					print "\tvars.telnet[\"telnet_" info[1] "\"] = {" > output_filename;
					print "\t\ttelnet_port = \"" info[1] "\"" > output_filename;
					print "\t}" > output_filename;
					print "" > output_filename;
				}
			}
			else if ( info[5] ~ /rmiregistry/ || info[5] ~ /java-rmi/ ) {
				if ( ICINGA2 ) {
					print "\tvars.rmi[\"rmi_" info[1] "\"] = {" > output_filename;
					print "\t\trmi_port = \"" info[1] "\"" > output_filename;
					print "\t}" > output_filename;
					print "" > output_filename;
				}
			}
			else if ( info[5] ~ /ms-sql/ ) {
				if ( ICINGA2 ) {
					print "\tvars.mssql[\"mssql_" info[1] "\"] = {" > output_filename;
					print "\t\tmssql_port = \"" info[1] "\"" > output_filename;
					print "\t}" > output_filename;
					print "" > output_filename;
				}
			}
			else if ( info[5] ~ /mysql/ ) {
				if ( ICINGA2 ) {
					print "\tvars.mysql[\"mysql_" info[1] "\"] = {" > output_filename;
					print "\t\tmysql_port = \"" info[1] "\"" > output_filename;
					print "\t}" > output_filename;
					print "" > output_filename;
				}
			}
		}
	}
	gsub(/, $/,"",ports);
	gsub(/, $/,"",groups);
	gsub(/;$/,"",known);
	gsub(/;$/,"",unknown);

	if ( ICINGA2 ) {
		print "\tvars.ports = [ " ports " ]" > output_filename;
		print "}" > output_filename;
		print "" > output_filename;
	}

	# Finalizing the host
	print "Host: " hosts[2] " - " hosts[3]
	print "Port List: "ports;
	print "Known services: "known;
	print "Unknown services: "unknown;
}
