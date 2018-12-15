---

title: Introducing mysql-snmp!
date: 2009-04-13 21:42:17 +02:00
comments: true
wordpress_id: 35
wordpress_url: http://www.masterzen.fr/?p=35
category:
- MySQL
- System Administration
- Monitoring
- snmp
tags:
- MySQL
- opennms
- snmp
- net-snmp
---
Thanks to [Days of Wonder](http://www.daysofwonder.com) the company I work for, I'm proud to release in Free Software (GPL):

## _**mysql-snmp**_ - monitor a MySQL server with SNMP

## History
At Days of Wonder, we're using MySQL for almost everything since the beginning of the company. We were initially monitoring all our infrastructure with [mon](http://www.kernel.org/pub/software/admin/mon/html/) and [Cricket](http://cricket.sourceforge.net/), including our MySQL servers.

Nine months ago I migrated the monitoring infrastructure to [OpenNMS](http://www.opennms.org), and at the same we lost the Cricket MySQL monitoring (which was done with direct SQL SHOW STATUS LIKE commands).

I had to find another way, and since OpenNMS excels at SNMP, it was natural to monitor MySQL through SNMP. My browsing crossed this [blog post.](http://mysqldump.azundris.com/archives/63-Sysadmins-Nightly-Mental-Pain-SNMP.html) At about the same time I noticed that Baron Schwartz had released some very good [MySQL Cacti Templates](http://code.google.com/p/mysql-cacti-templates/), so I decided I should cross both project and started working on mysql-snmp on my free time.

Hopefully, Days of Wonder has an IANA SNMP enterprises sub-number (20267, we use this for monitoring our game servers), so the MIB I wrote for this project is hosted in a natural place in the MIB hierarchy.

## What's this?
It's a[ Net-SNMP](http://www.net-snmp.org/) perl subagent that connects to your [MySQL server](http://www.mysql.com/), and reports various statistics (from show status or show innodb status, or even replication) through SNMP.## But wait, there's more, there's OpenNMS support!

If you followed this blog from the very start, you know we're using OpenNMS to monitor Days of Wonder infrastructure. So I included the various OpenNMS configuration bit to display nice and usable graphs, inspired by the excellent MySQL Cacti Templates.

Here are some examples:

[![InnoDB transactions](/images/uploads/2009/04/innodbtransaction-300x145.png "innodbtransaction")](/images/uploads/2009/04/innodbtransaction.png)

[![InnoDB Buffer Pool](/images/uploads/2009/04/bufferpool-300x145.png "bufferpool")](/images/uploads/2009/04/bufferpool.png)

## So, I want it! Where should I look?
The code is hosted in [my github repository](http://github.com/masterzen/mysql-snmp/tree/master), and everything you should know is in the [mysql-snmp page on my site](/software-contributions/mysql-snmp-monitor-mysql-with-snmp/).

If you use this software, please do not hesitate to contribute, and/or fix bugs :-)
