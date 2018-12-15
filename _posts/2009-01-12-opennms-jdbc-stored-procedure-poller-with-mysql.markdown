---
title: OpenNMS JDBC Stored Procedure Poller with MySQL
date: 2009-01-12 22:36:13 +01:00
comments: true
wordpress_id: 7
wordpress_url: http://www.masterzen.fr/?p=7
category: 
- MySQL
- System Administration
- Monitoring
tags: 
- MySQL
- opennms
- monitoring
- sql
- procedure
---
Since a few months we are monitoring our infrastructure at [Days of Wonder](http://www.daysofwonder.com) 
with [OpenNMS](http://www.opennms.org). Until this afternoon we were running the beta/final candidate version 1.5.93.

We are monitoring a few things with the [JDBC Stored Procedure Poller](http://www.opennms.org/index.php/JDBC_stored_procedure_monitor), which
is really great to monitor complex business operations without writing remote or GP scripts. 

Unfortunately the migration to OpenNMS 1.6.1 led me to discover
that the JDBC Stored Procedure poller was not working anymore, crashing with a
NullPointerException in the MySQL JDBC Driver while trying to fetch the output
parameter.

In fact it turned out I was plain wrong. I was using a MySQL
PROCEDURE:

``` sql
DELIMITER //
CREATE PROCEDURE `check_for_something`()
READS SQL DATA
BEGIN
 SELECT ... as valid FROM ...
END
//
```

But this OpenNMS poller uses the following JDBC procedure
call:
``` java
{ 
  ? = call check_for_something()
}
```

After a few struggling, wrestling, and various MySQL JDBC
Connector/J driver upgrades, I finally figured out what the driver was
doing: The driver rewrites the call I gave above to something like
this:

``` sql
SELECT check_for_something();
```

This means that the procedure should in fact be a SQL FUNCTION.

Here is the same procedure rewritten as a
FUNCTION:

``` sql
DELIMITER //
CREATE FUNCTION `check_for_something`()
RETURNS int(11)
READS SQL DATA
DETERMINISTIC
BEGIN
  DECLARE valid INTEGER;
  SELECT ... INTO valid FROM ...RETURN valid;
END
//
```

It now works. I'm amazed it even worked in the first place
with 1.5.93 (it was for sure).
