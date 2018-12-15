--- 

title: MySQL InnoDB and table renaming don't play well...
date: 2009-10-15 06:52:08 +02:00
comments: true
wordpress_id: 116
wordpress_url: http://www.masterzen.fr/?p=116
category: 
- MySQL
- War stories
- System Administration
tags: 
- oom
- rename
- patch
- InnoDB
- memory
- memory leak
- MySQL
- mysql patch
---
At Days of Wonder we are huge fans of [MySQL](http://www.mysql.com/) (and since about a year of the various [Open Query](http://ourdelta.org/), [Percona](http://www.percona.com/percona-lab.html), [Google](http://code.google.com/p/google-mysql-tools/wiki/Mysql5Patches) or other community patches), up to the point we're using MySQL for about everything in production.

But since we moved to 5.0, back 3 years ago our production databases which hold our website and online game systems has a unique issue: the mysqld process uses more and more RAM, up to the point where the [kernel OOM](http://linux-mm.org/OOM_Killer) decide to kill the process.

You'd certainly think we are complete morons because we didn't do anything in the last 3 years to fix the issue :-)

Unfortunately, I never couldn't replicate the issue in the lab, mainly because it is difficult to replicate the exact same load the production server sees (mainly because of the online games activity).

During those 3 years, I tried everything I could, from using other allocators, valgrind, debug builds and so on, without any success.

What is nice, is that we moved to an [OurDelta](http://ourdelta.org/) build about a year ago, where [InnoDB](http://www.innodb.com/) is able to print more memory statistics than the default MySQL version.

For instance it shows
```
Internal hash tables (constant factor + variable factor)
    Adaptive hash index 1455381240      (118999688 + 1336381552)
    Page hash           7438328
    Dictionary cache    281544240       (89251896 + 192292344)
    File system         254712  (82672 + 172040)
    Lock system         18597112        (18594536 + 2576)
    Recovery system     0       (0 + 0)
    Threads             408056  (406936 + 1120)
    innodb_io_pattern   0       (0 + 0)
```
Back several month ago, I analyzed this output just to see what figures were growing, and found that the _Dictionary Cache variable part _was increasing (slowly but definitely).

Sure fine MySQL experts would have been able to tell me exactly what, when and where the problem was, but since I'm not familiar with the code-base, I looked up what this number was and where it was increased (all in _dict0dict.c_) and added some logs each time it was increased.

I then installed this version for a quite long time (just to check it wouldn't crash on production) on a slave server. But this server didn't print anything interesting because it doesn't see the exact same load the production masters.

A couple of months after that, I moved this code to one of the master and bingo! I found the operation and the tables exhibiting an increase:
``` bash
mysqld[8131]: InnoDB: dict_table_rename_in_cache production/rank_tmp2 193330680 + 8112
mysqld[8131]: InnoDB: dict_table_rename_in_cache production/rank 193338792 + 8112
```
As soon as I saw the operation and table (ie rank), I found what the culprit is. We have a daemon that every 10s computes the player ranks for our online games.

To do this, we're using the following pattern:
``` sql
-- compute the ranks
SELECT NULL, playerID
FROM game_score as g
ORDER BY g.rankscore DESC
INTO OUTFILE "/tmp/rank_tmp.tmp"

-- load back the scores
LOAD DATA INFILE "/tmp/rank_tmp.tmp" INTO TABLE rank_tmp

-- swap tables so that clients see new ranks atomatically
RENAME TABLE rank TO rank_tmp2 , rank_tmp TO rank, rank_tmp2 TO rank_tmp

-- truncate the old ranks for a new pass
TRUNCATE TABLE rank_tmp

-- go back to the select above
```

You might ask why I'm doing a so much convoluted system, especially the SELECT INTO OUTFILE and the LOAD DATA. It's just because INSERT ... SELECT with innodb and binlog enabled can produce transactions abort (which we were getting tons of).

Back to the original issue, apparently the issue lies in the RENAME part of the daemon.

Looking at the _dict0dict.c dict_table_rename_in_cache_ function we see:
``` c

ibool
dict_table_rename_in_cache(...)
...
  old_name = mem_heap_strdup(table->heap, table->name);
  table->name = mem_heap_strdup(table->heap, new_name);
...
}

```

Looking to _mem_heap_ stuff, I discovered that each table has a heap associated in which InnoDB allocates various things. This heap can only grow (by block of 8112 bytes it seems), since the allocator is not a real one. This is done for performance reasons.

So each time we rename a table, the old name (why? since it is already allocated) is duplicated, along with the new name. Each time.

This heap is freed when the table is dropped, so there is a possibility to reclaim the used memory. That means this issue is not a memory leak per-se.

By the way, I've [filed this bug on mysql bug system](http://bugs.mysql.com/?id=47991).

One work-around, beside fixing the code itself, would be to drop the rank table instead of truncating it. The issue with dropping/creating InnoDB table on a fast pace is that the dictionary cache itself will grow, because it can only grow as there is no way to purge it from old tables (except running one of the Percona patches). So the more tables we create the more we'll use memory - back to square 0, but worst.

So right now, I don't really have any idea on how to really fix the issue. Anyone having an idea, please do not hesitate to comment on this blog post :-)

And please, don't tell me to move to MyISAM...

