--- 

title: The curse of bad blocks (is no more)
date: 2009-02-01 11:36:06 +01:00
comments: true
wordpress_id: 16
wordpress_url: http://www.masterzen.fr/?p=16
category: 
- System Administration
- War stories
tags: 
- disk
- scsi
- failed sector
- smartmontools
- sg3_utils
- backup
- disk defect
---
If you like me are struggling with old disks (in my case _SCSI 10k RPM Ultra Wide 2 HP disks_) that exhibits 
_bad blocks_, here is a _short survival howto_. 

Those disks are placed in a refurbished [HP Network RS/12](http://h20000.www2.hp.com/bizsupport/TechSupport/SupportTaskIndex.jsp?lang=en&cc=us&taskId=115&prodSeriesId=62500&prodTypeId=3447589) 
I use as a spool area for [Bacula](http://www.bacula.org) backups of 
our [Apple XServe RAID ](http://www.apple.com/server/storage/)
which is used by [Days of Wonder](http://www.daysofwonder.com) graphic Studio (and those guys knows how to produce 
huge files, trust me).

Since a couple of days, one of the disk _exhibits read errors on some sectors_ (did I say they are old), 
so waiting to get replaced by other (old) disks, I had to find a way to have it working.

Of course the SCSI utility in the [Adaptec SCSI card](http://www.adaptec.com/en-US/products/Controllers/Hardware/scsi/entry/ASC-39160/) 
has a remapping tool, but you have to reboot the server and have it **offline during the verify**, which can 
take a long time, so that wasn't an option.

I then learnt about [sg3_utils](http://tldp.org/HOWTO/SCSI-Generic-HOWTO/sg3_utils.html) 
([sg3-utils for the debian package](http://packages.debian.org/etch/sg3-utils)) 
thanks to the [very good page of smartmontools bad blocks handling](http://smartmontools.sourceforge.net/badblockhowto.html).

This set of tools directly address SCSI disks through mode page, to instruct the disk to do some things. 
What's interesting is that it comes with two commands of great use (there might be more  of course):

- **_sg_verify_**: to check for the health of a sector
- **_sg_reassign_**: to remap a dead sector to one from the good sector list

Here is the use case:
```
backup:~# dd if=/dev/sda iflag=direct of=/dev/zero skip=1915 bs=1M
dd: reading `/dev/sda': Input/output error
12+0 records in
12+0 records out
12582912 bytes (13 MB) copied, 1.41468 seconds, 8.9 MB/s
```

Something is wrong, we only read _13MB_ instead of the whole disk.
Let's have look to the kernel log:

```
backup:~# dmesg | tail
[331709.192108] sd 0:0:0:0: [sda] Result: hostbyte=DID_OK driverbyte=DRIVER_SENSE,SUGGEST_OK
[331709.192108] sd 0:0:0:0: [sda] Sense Key : Medium Error [current]
[331709.192108] Info fld=0x3c3bb1
[331709.192108] sd 0:0:0:0: [sda] Add. Sense: Read retries exhausted
[331709.192108] end_request: I/O error, dev sda, sector 3947441
```

Indeed /dev/sda has a failed sector (at[ ](http://en.wikipedia.org/wiki/Logical_block_addressing)_[lba](http://en.wikipedia.org/wiki/Logical_block_addressing) 3947441_).

Let's confirm it:

```
backup:~# sg_verify --lba=3947441 /dev/sdaverify
 (10):  Fixed format, current;  
 Sense key: Medium Error Additional sense: Read retries exhausted  
 Info fld=0x3c3bb1 [3947441]  
 Actual retry count: 0x003f
 medium or hardware error, reported lba=0x3c3bb1
```

Check the defect list:
```
sg_reassign --grown /dev/sda
>> Elements in grown defect list: 0
```

And tell the disk firmware to reassign the sector

```
backup:~# sg_reassign --address=3947441 /dev/sda
```

Now verify that it was remapped:
```
backup:~# sg_reassign --grown /dev/sda
>> Elements in grown defect list: 1
```

Do we have a working sector?
```
backup:~# dd if=/dev/sda iflag=direct of=/dev/null bs=512 count=1 skip=3947441
1+0 records in
1+0 records out
512 bytes (512 B) copied, 0.00780813 seconds, 65.6 kB/s
```

The sector could be read! The disk is now safe.

Of course, this tutorial might not work for every disks: PATA and SATA disks don't respond to SCSI commands. 
For those disks, you have to write on the failed sector with dd and the disk firmware should automatically remap 
the sector. This can be proved by looking at the **Reallocated_Sector_Ct **output of ``smartctl -a``.

Good luck :-)
