#!/usr/bin/perl -w
#

### Nmap2Icinga2 (
#
#This perl script will take a nmap generated "grepable" file and create the host definitions for Icinga2
# nmap <IP Range> -s[S|T|A|W] -O -oG <FILENAME>
# ./nmap2icinga2.pl <FILENAME>
# You need to add the service.cfg, command.cfg & the hostgroups.cfg below to your existing files
# 
# Based on the plugin nbi.pl https://exchange.nagios.org/directory/Addons/Configuration/Nagios-Bulk-Import-(nbi-2Epl)/details
# Originaly created on Jan 16, 2012 by ldecker (ldecker@gmail.com)
# License: GPL
# 
# Modified by joydragon (https://twitter.com/joy_dragon on Aug 1, 2016
# Licence: MIT


use strict;
use warnings;

my(@dataseg, @tempseg, $recfile, $recline, $out1, $elem, $i, $portflg, $osflg, $httpflag, $httpsflag);
my($hostname, $hostaddr, $hostos, $hostosfull, $hostports, $openptrport, $tempfile, $outhost);

sub init
{
 if( $#ARGV eq -1 or $ARGV[0] eq "--help")
 {
  print "$0 <(nmap <IP Range> -s[S|T|A] -O -oG) INPUT FILE>\n";
  exit;
 }
 else
 {
  $recfile=$ARGV[0];
  $outhost="hosts.cfg";
  $tempfile="tempfile$$";
  system("rm $outhost tempfile*");
# This grep statement removes all the "Status: Up" lines and replaces the () with ^ so the hostname will equal the hostIP - there was no DNS entry
  system("grep -v -e 'Status: Up' $recfile | sed  \"s/\(\)/^/g\"  | sed  \"s/\(//g\" | sed \"s/\)//g\" | sed \"s/\\//\|/g\" | sed \"s/\|\|\|/\|/g\" | sed \"s/\|\|/\|/g\"  | sed \"s/\t/ /g\" | grep -i -v nmap > $tempfile");
 }
}

sub read_nmap
{
 open(OUTHOST,"> $outhost");
 open(RECFILE,"< $tempfile");
 while($recline=<RECFILE>)
{
  if(length($recline)>0)
  {
   chomp($recline);
   @dataseg = split(/ /,$recline);
   $elem = @dataseg;
   $openptrport=0;
   $portflg=0;
   $osflg=0;
   $httpflag=0;
   $httpsflag=0;
   $hostports="";
   $hostos="";
   $hostosfull="";
   $hostaddr=$dataseg[1];
# Set the hostname equal to the hostIP - there was no DNS entry
   $hostname=($dataseg[2] eq '^')?$dataseg[1]:$dataseg[2];
   for($i=2;$i<$elem;$i++)
   {
    if($dataseg[$i] eq "Ports:") { $osflg=0;$portflg=1; }
    elsif($dataseg[$i] eq "OS:") { $portflg=0;$osflg=1; }
    elsif($portflg)
    {
     if($dataseg[$i] =~ /open/)
     {
      @tempseg = split(/\|/,$dataseg[$i]);
# This switch block is used to setup the hostgroup membership based on the ports that were
# found open during the nmap run
      $hostports = $hostports."\"".$tempseg[0]."\", "; 
     }   
    }
    elsif($osflg)
    {
     if($dataseg[$i] =~ /Linux|HP-UX|NetBSD|Solaris|Centos/i) { $hostos="Linux"; $hostosfull=$dataseg[$i]; $osflg=0; }
     elsif($dataseg[$i] =~ /Microsoft/i)               { $hostos="Windows"; $hostosfull=$dataseg[$i]; $osflg=0; }
     elsif($dataseg[$i] =~ /Cisco/i)                   { $hostos="Switch"; $hostosfull=$dataseg[$i]; }
     elsif($dataseg[$i] =~ /Aironet/i)                 { $hostos="Switch"; $hostosfull=$dataseg[$i]; $osflg=0; }
     elsif($dataseg[$i] =~ /Juniper/i)                 { $hostos="Firewall"; $hostosfull=$dataseg[$i]; }
     elsif($dataseg[$i] =~ /Dell/i)                    { $hostos="Storage"; $hostosfull=$dataseg[$i]; }
     elsif($dataseg[$i] =~ /printer/i)                 { $hostos="Printer"; $hostosfull=$dataseg[$i]; $osflg=0; }
     elsif($dataseg[$i] =~ /VxWorks/i)                 { $hostos="Device"; $hostosfull=$dataseg[$i]; $osflg=0; }
     elsif($dataseg[$i] =~ /HP/i)                      { $hostos="HP"; $hostosfull=$dataseg[$i]; }
     elsif($dataseg[$i] =~ /APC/i)                     { $hostos="UPS"; $hostosfull=$dataseg[$i]; $osflg=0; }
     elsif($dataseg[$i] =~ /:/)                        { $osflg=0; }
    }
   }
# Cleaning ports and groups
   if($hostports ne ""){
     $hostports = substr($hostports, 0, length($hostports)-2);
   }

# Default host OS if no host OS was found
   if($hostos eq "") { $hostos="Windows"; }
   $out1=sprintf("
object Host \"%s\" {
   import \"generic-host\"

   address = \"%s\"
   display_name = \"%s\"

   vars.os = \"%s\"
   vars.os_full = \"%s\"
   vars.ports = [ %s ]\n", $hostaddr, $hostaddr, $hostname, $hostos, $hostosfull, $hostports);
   if($httpflag){
     $out1.=sprintf("
   vars.http_vhosts[\"http\"] = {
       http_uri = \"/\"
   }")
   }
   if($httpsflag){
     $out1.=sprintf("
   vars.http_vhosts[\"https\"] = {
       http_uri = \"/\"
       http_ssl = \"1\"
   }")
   }

   $out1.=sprintf("\n}\n");

   print OUTHOST $out1;
  }
 }
 close(OUTHOST);
 close(RECFILE);
}

&init;
&read_nmap;
