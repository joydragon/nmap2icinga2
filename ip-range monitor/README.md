#IP-Range Monitor

Here is the script for the new part, the IP-Range Monitor

First you must have access to the icinga2 API, you can check how to do this on the Icinga2 documentation https://www.icinga.com/docs/icinga2/latest/doc/12-icinga2-api/

After the permissions setup you must run this script with just the one parameter:
```
check_ip_range.sh -H <IP or Range>

check_ip_range.sh -H 10.0.0.10

check_ip_range.sh -H 192.168.0.0/24
```

With that you'll have a lot of files running around on the /tmp folder of the type icinga2-monitor-log-[some sha256], check them out :)
