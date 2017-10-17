#IP-Range Monitor

Here is the script for the new part, the IP-Range Monitor

First you must have access to the icinga2 cli, my solution was to add the current user to the sudoers file with the icinga (and nmap) permissions.

If the user you are running this script is already icinga, you don't need to use the sudo on that part of the icinga file, but is recommended for the nmap
```
[/etc/sudoers.d/nmap_icinga_permissions]
script_user  ALL = NOPASSWD:/usr/bin/nmap,/usr/sbin/icinga2
```

After the permissions setup you must run this script with just the one parameter:
```
check_ip_range.sh <IP or Range>

check_ip_range.sh 10.0.0.10

check_ip_range.sh 192.168.0.0/24
```

With that you'll have a lot of files running around
