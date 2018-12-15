---

title: mysql-snmp 1.0 - SNMP monitoring for MySQL
date: 2010-01-10 18:14:06 +01:00
comments: true
wordpress_id: 149
wordpress_url: http://www.masterzen.fr/?p=149
category:
- Programming
- snmp
- Monitoring
- System Administration
- MySQL
- Perl
tags:
- net-snmp
- snmp
- monitoring
- opennms
- MySQL
---

I'm really proud to announce the release of the version 1.0 of [mysql-snmp](http://www.masterzen.fr/software-contributions/mysql-snmp-monitor-mysql-with-snmp/).


## What is mysql-snmp?


**mysql-snmp** is a mix between the excellent [MySQL Cacti Templates](http://code.google.com/p/mysql-cacti-templates/) and a [Net-SNMP agent](http://www.net-snmp.org/). The idea is that combining the power of the _MySQL Cacti Templates_ and any SNMP based monitoring would unleash a powerful mysql monitoring system. Of course this project favorite monitoring system is [OpenNMS](http://www.opennms.org/wiki/Main_Page).


**mysql-snmp** is shipped with the necessary [OpenNMS](http://www.opennms.org/wiki/Main_Page) configuration files, but any other SNMP monitoring software can be used (provided you configure it).


To get there, you need to run a SNMP agent on each MySQL server, along with **mysql-snmp**. Then OpenNMS (or any SNMP monitoring software) will contact it and fetch the various values.


Mysql-snmp exposes a lot of useful values including but not limited to:



- SHOW STATUS values
- SHOW ENGINE INNODB STATUS parsed values (MySQL 5.0, 5.1, XtraDB or Innodb plugin are supported)


Here are some graph examples produced with OpenNMS 1.6.5 and mysql-snmp 1.0 on one of Days of Wonder MySQL server (running a MySQL 5.0 Percona build):


[![commands](/images/uploads/2010/01/commands-300x187.jpg "MySQL command counters")](http://www.masterzen.fr/wp-content/uploads/2010/01/commands.jpg)

[![mem](/images/uploads/2010/01/mem-300x163.jpg "Innodb Memory Usage")](http://www.masterzen.fr/wp-content/uploads/2010/01/mem.jpg)

[![tmp](/images/uploads/2010/01/tmp-300x145.jpg "tmp")](/images/uploads/2010/01/tmp.jpg)

[![innodbwrites](/images/uploads/2010/01/innodbwrites-300x145.jpg "innodbwrites")](http://www.masterzen.fr/wp-content/uploads/2010/01/innodbwrites.jpg)

[![graph](/images/uploads/2010/01/graph-300x145.jpg "graph")](http://www.masterzen.fr/wp-content/uploads/2010/01/graph.jpg)

[![tablelocks](/images/uploads/2010/01/tablelocks-300x145.jpg "tablelocks")](http://www.masterzen.fr/wp-content/uploads/2010/01/tablelocks.jpg)


## Where to get it

mysql-snmp is available in my [github repository](http://github.com/masterzen/mysql-snmp). The repository contains a spec file to build a RPM and what is needed to build a Debian package. Refer to the [README](http://github.com/masterzen/mysql-snmp/blob/master/README) or the [mysql-snmp page ](http://www.masterzen.fr/software-contributions/mysql-snmp-monitor-mysql-with-snmp/)for more information.

Thanks to gihub, it is possible to download the tarball instead of using Git:

[Mysql-snmp v1.0 tarball](http://github.com/masterzen/mysql-snmp/tarball/v1.0)


## Changelog

This lists all new features/options from the initial version v0.6:

- Spec file to build RPM
- Use of configuration file for storing mysql password
- Fix of slave handling
- Fix for mk-heartbeat slave lag
- Support of InnoDB plugin and Percona XtraDB
- Automated testing of InnoDB parsing
- Removed some false positive errors
- OpenNMS configuration generation from MySQL Cacti Templates core files
- 64 bits computation done in Perl instead of (ab)using MySQL
- More InnoDB values (memory, locked tables, ...)

## Reporting Issues

Please use [Github issue system](http://github.com/masterzen/mysql-snmp/issues) to report any issues.

## Requirements

There is a little issue here. **mysql-snmp** uses Net-Snmp. Not all versions of Net-Snmp are supported as some older versions have some bug for dealing with Counter64. [Version 5.4.2.1](http://sourceforge.net/projects/net-snmp/files/) with [this patch](http://sourceforge.net/tracker/?func=detail&aid=2890931&group_id=12694&atid=312694) is known to work fine.

Also note that this project uses some Counter64, so make sure you configure your SNMP monitoring software to use SNMP v2c or v3 (SNMP v1 doesn't support 64 bits values).

## Final words!

I wish everybody an happy new year. Consider this new version as my Christmas present to the community :-)
