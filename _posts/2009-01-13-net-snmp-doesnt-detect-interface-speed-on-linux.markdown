---
title: Net-Snmp doesn't detect interface speed on Linux
wordpress_id: 8
wordpress_url: http://www.masterzen.fr/?p=8
category: 
- System Administration
- snmp
tags: 
- snmp
- net-snmp
- interface
- linux
- permission
---
_Have you ever wondered why [net-snmp](http://www.net-snmp.org/ "Net-Snmp") doesn't report a ccomments: true
orrect interface speed on Linux?_

I was also wondering, until this morning... 

I tried to run net-snmp as root, and miracle, the right interface speed was detected for my interfaces.
In fact net-snmp uses the **``SIOCETHTOOL``** ioctl to access this information. 
Unfortunately the _get settings_ variant of this ioctl needs to have the **``CAP_NET_ADMIN ``**enabled. 

Of course ``root`` has this capability set, but when net-snmp drops its privileges to an unprivileged user, 
this capability is lost and the ``ioctl`` fails with **``EPERM``**.

That's too bad because getting this information is at most harmless and shouldn't require special 
privileges to succeed. 

Someone even posted a [Linux Kernel patch to remove CAP_NET_ADMIN check for SIOCETHTOOL](http://oss.sgi.com/archives/netdev/2003-06/msg00641.html) 
which doesn't seem to have been merged.

The fix could also be on the snmpd side before dropping privileges.

The workaround is to tell _net-snmp_ how the interface are looking:
```
interface eth0 6 10000000
interface eth1 6 100000000
```

Here I defined _eth0_ as a 100mbit/s FastEthernet interface, and _eth1_ as a GigabitEthernet interface.

