---

title: "redis-snmp: redis performance monitoring through SNMP"
date: 2011-12-25 17:49:18
comments: true
categories:
- Sysadmin
- Monitoring
tags:
- redis
- monitoring
- sysadmin
- snmp
---
The same way I created [mysql-snmp](/software-contributions/mysql-snmp-monitor-mysql-with-snmp/) a small [Net-SNMP](http://www.net-snmp.org/) subagent that allows exporting performance data from MySQL through SNMP, I'm proud to announce the first release of **redis-snmp** to monitor [Redis servers](http://redis.io/). It is also inspired by the [Cacti MySQL Templates](http://code.google.com/p/mysql-cacti-templates/) (which also covers Redis).

I originally created this Net-SNMP perl subagent to monitor some Redis performance metrics with [OpenNMS](http://www.opennms.org/).

## The where

You'll find the sources (which allows to produce a debian package) in the [redis-snmp github repository](http://github/masterzen/redis-snmp)

## The what

Here are the kind of graphs and metrics you can export from a redis server:

![Redis Connections](/images/uploads/2011/12/redis-connections.jpg "Redis Connections")

![Redis Commands](/images/uploads/2011/12/redis-commands.jpg "Redis Commands")

![Redis Memory](/images/uploads/2011/12/redis-memory.jpg "Redis Memory")

## The how

Like mysql-snmp you need to run redis-snmp on a host that has a connectivity with the monitored redis server (the same host makes sense). You also need the following dependencies:

* Net-SNMP >= 5.4.2.1 (older versions contains a 64 bits varbind issue)
* perl (tested under perl 5.10 from debian squeeze)

Once running, you should be able to ask your snmpd about redis values:

```sh
$ snmpbulkwalk -m'REDIS-SERVER-MIB' -v 2c  -c public redis-server.domain.com .1.3.6.1.4.1.20267.400
REDIS-SERVER-MIB::redisConnectedClients.0 = Gauge32: 1
REDIS-SERVER-MIB::redisConnectedSlaves.0 = Gauge32: 0
REDIS-SERVER-MIB::redisUsedMemory.0 = Counter64: 154007648
REDIS-SERVER-MIB::redisChangesSinceLastSave.0 = Gauge32: 542
REDIS-SERVER-MIB::redisTotalConnections.0 = Counter64: 6794739
REDIS-SERVER-MIB::redisCommandsProcessed.0 = Counter64: 37574019
```

Of course you must adjust the hostname and community. SNMP v2c (or better) is mandatory since we're reporting 64 bits values. 

Note that you can get the OID translation to name only if the REDIS-SNMP-SERVER MIB is installed on the host where you run the above command.

## OpeNMS integration

To integrate to OpenNMS, it's as simple as adding the following group to your ``datacollection-config.xml`` file:

```xml
<!-- REDIS-SERVER MIB -->
<group name="redis" ifType="ignore">
    <mibObj oid=".1.3.6.1.4.1.20267.400.1.1" instance="0" alias="redisConnectedClnts" type="Gauge32" />
    <mibObj oid=".1.3.6.1.4.1.20267.400.1.2" instance="0" alias="redisConnectedSlavs" type="Gauge32" />
    <mibObj oid=".1.3.6.1.4.1.20267.400.1.3" instance="0" alias="redisUsedMemory" type="Gauge64" />
    <mibObj oid=".1.3.6.1.4.1.20267.400.1.4" instance="0" alias="redisChangsSncLstSv" type="Gauge32" />
    <mibObj oid=".1.3.6.1.4.1.20267.400.1.5" instance="0" alias="redisTotalConnectns" type="Counter64" />
    <mibObj oid=".1.3.6.1.4.1.20267.400.1.6" instance="0" alias="redisCommandsPrcssd" type="Counter64" />
</group>
```

And the following graph definitions to your ``snmp-graph.properties`` file:

```
report.redis.redisconnections.name=Redis Connections
report.redis.redisconnections.columns=redisConnectedClnts,redisConnectedSlavs,redisTotalConnectns
report.redis.redisconnections.type=nodeSnmp
report.redis.redisconnections.width=565
report.redis.redisconnections.height=200
report.redis.redisconnections.command=--title "Redis Connections" \
 --width 565 \
 --height 200 \
 DEF:redisConnectedClnts={rrd1}:redisConnectedClnts:AVERAGE \
 DEF:redisConnectedSlavs={rrd2}:redisConnectedSlavs:AVERAGE \
 DEF:redisTotalConnectns={rrd3}:redisTotalConnectns:AVERAGE \
 LINE1:redisConnectedClnts#9B2B1B:"REDIS Connected Clients         " \
 GPRINT:redisConnectedClnts:AVERAGE:"Avg \\: %8.2lf %s" \
 GPRINT:redisConnectedClnts:MIN:"Min \\: %8.2lf %s" \
 GPRINT:redisConnectedClnts:MAX:"Max \\: %8.2lf %s\\n" \
 LINE1:redisConnectedSlavs#4A170F:"REDIS Connected Slaves          " \
 GPRINT:redisConnectedSlavs:AVERAGE:"Avg \\: %8.2lf %s" \
 GPRINT:redisConnectedSlavs:MIN:"Min \\: %8.2lf %s" \
 GPRINT:redisConnectedSlavs:MAX:"Max \\: %8.2lf %s\\n" \
 LINE1:redisTotalConnectns#38524B:"REDIS Total Connections Received" \
 GPRINT:redisTotalConnectns:AVERAGE:"Avg \\: %8.2lf %s" \
 GPRINT:redisTotalConnectns:MIN:"Min \\: %8.2lf %s" \
 GPRINT:redisTotalConnectns:MAX:"Max \\: %8.2lf %s\\n"

report.redis.redismemory.name=Redis Memory
report.redis.redismemory.columns=redisUsedMemory
report.redis.redismemory.type=nodeSnmp
report.redis.redismemory.width=565
report.redis.redismemory.height=200
report.redis.redismemory.command=--title "Redis Memory" \
  --width 565 \
  --height 200 \
  DEF:redisUsedMemory={rrd1}:redisUsedMemory:AVERAGE \
  AREA:redisUsedMemory#3B7AD9:"REDIS Used Memory" \
  GPRINT:redisUsedMemory:AVERAGE:"Avg \\: %8.2lf %s" \
  GPRINT:redisUsedMemory:MIN:"Min \\: %8.2lf %s" \
  GPRINT:redisUsedMemory:MAX:"Max \\: %8.2lf %s\\n"

report.redis.rediscommands.name=Redis Commands
report.redis.rediscommands.columns=redisCommandsPrcssd
report.redis.rediscommands.type=nodeSnmp
report.redis.rediscommands.width=565
report.redis.rediscommands.height=200
report.redis.rediscommands.command=--title "Redis Commands" \
 --width 565 \
 --height 200 \
 DEF:redisCommandsPrcssd={rrd1}:redisCommandsPrcssd:AVERAGE \
 AREA:redisCommandsPrcssd#FF7200:"REDIS Total Commands Processed" \
 GPRINT:redisCommandsPrcssd:AVERAGE:"Avg \\: %8.2lf %s" \
 GPRINT:redisCommandsPrcssd:MIN:"Min \\: %8.2lf %s" \
 GPRINT:redisCommandsPrcssd:MAX:"Max \\: %8.2lf %s\\n"

report.redis.redisunsavedchanges.name=Redis Unsaved Changes
report.redis.redisunsavedchanges.columns=redisChangsSncLstSv
report.redis.redisunsavedchanges.type=nodeSnmp
report.redis.redisunsavedchanges.width=565
report.redis.redisunsavedchanges.height=200
report.redis.redisunsavedchanges.command=--title "Redis Unsaved Changes" \
  --width 565 \
  --height 200 \
  DEF:redisChangsSncLstSv={rrd1}:redisChangsSncLstSv:AVERAGE \
  AREA:redisChangsSncLstSv#A88558:"REDIS Changes Since Last Save" \
  GPRINT:redisChangsSncLstSv:AVERAGE:"Avg \\: %8.2lf %s" \
  GPRINT:redisChangsSncLstSv:MIN:"Min \\: %8.2lf %s" \
  GPRINT:redisChangsSncLstSv:MAX:"Max \\: %8.2lf %s\\n"
 
```

Do not forget to register the new graphs in the report list at the top of ``snmp-graph.properties`` file.

Restart OpenNMS, and it should start graphing your redis performance metrics.
You'll find those files in the opennms directory of the source distribution.

Enjoy :)
