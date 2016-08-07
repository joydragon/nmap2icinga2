##
# This script is part of the nmap2icinga2 script published on Github by JoyDragon, https://github.com/joydragon/nmap2icinga2/
# Using MIT licence
# Please don't remove this comments when using the script.

BEGIN {FS="\t"}
{
        ICINGA2 = 1;
        output_filename="processed.conf";

        # Here is the Host information
        split($1,hosts," ");
        # hosts[2]      # Host Address
        # hosts[3]      # Host Name (if any)
        if( hosts[3] == "()" )
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
        # oss[2]        # Os name resolution (if any)
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
        # Start processing the ports for the node
        split($2,arr_ports,",");
        gsub(/Ports:/,"",arr_ports[1]);
        ports=""
        known=""
        unknown=""
        for( i=1; i<length(arr_ports); i++)
        {
                # Trimming the information
                gsub(/^[ \t]+/,"",arr_ports[i]);
                gsub(/[ \t]+$/,"",arr_ports[i]);

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

                        if ( info[5] ~ /http/ ) {
                                if ( ICINGA2 ) {
                                        print "\tvars.http_vhosts[\"http_" info[1] "\"] = {" > output_filename;
                                        print "\t\thttp_port = \"" info[1] "\"" > output_filename;
                                        print "\t\thttp_uri = \"/\"" > output_filename;
                                        if( info[5] ~ /ssl/ ){
                                                print "\t\thttp_ssl = 1" > output_filename;
                                        }
                                        print "\t}" > output_filename;
                                        print "" > output_filename;
                                }
                        }
                }
        }
        gsub(/, $/,"",ports);
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
