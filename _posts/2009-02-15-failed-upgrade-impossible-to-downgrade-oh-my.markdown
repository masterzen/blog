--- 

title: Failed upgrade, impossible to downgrade... Oh my...
date: 2009-02-15 19:27:45 +01:00
comments: true
wordpress_id: 19
wordpress_url: http://www.masterzen.fr/?p=19
category: 
- System Administration
- War stories
tags: 
- War stories
- upgrade
- 802.3ad
- channel-group
- dell
- network
- bonding
---
In the [Days of Wonder](http://www.daysofwonder.com) [Paris Office](http://www.daysofwonder.com/en/contact/) 
(where is located our graphic studio, and incidentally where I work), 
we are using [Bacula](http://www.bacula.org) to perform the multi-terabyte backup 
of the laaaaarge graphic files the studio produces every day.

The _setup_ is the following:

- one _linux box_ as the [Bacula director](http://www.bacula.org/en/rel-manual/Configuring_Director.html#DirectorChapter) connected to
- an [Overland Arcvault 24 LTO 4](http://www.overlandstorage.com/US/products/arcvault24.html), and to
- an [HP Network Server RS/12](http://www.rql.kiev.ua/RQL/old/HP/SERVER/rackstorage12_12fc.htm) scsi cabinet (with 4  15k RPM disks)
- one [Apple Xserve](http://www.apple.com/xserve/) which acts as the studio filer, connected through two FiberChannel links to
- one [Apple Xserve RAID](http://www.apple.com/support/xserveraid/) fully loaded with 500GB disks
- and in the middle a "small" [Dell 5324 Gigabit Switch](http://www.dell.com/content/products/productdetails.aspx/pwcnt_5324), which acts as a [collapsed core](http://en.wikipedia.org/wiki/Collapsed_Backbone) for the office.

Both servers are connected to the switch through 
[two gigabit ethernet copper links](http://en.wikipedia.org/wiki/Gigabit_ethernet#1000BASE-T), 
each one forming a [802.3ad](http://en.wikipedia.org/wiki/802.3ad) link.
The Apple Xserve and the linux box uses a layer3 hash algorithm to spread the load 
between each slave.

OK, that's the fine print.

Usually about network gears, I'm pretty [Cisco](http://www.cisco.com) only (sorry, but I never found anything better than IOS).
When we installed this setup back in 2006, the management decided to not go the full cisco route for the office 
network because of the price (a Dell 5324 is about 800 EUR, compared to a 2960G-24 which is more around 2000 EUR).

So, this switch was installed there, and never received an update (_if it ain't broken don't fix it_ is my motto). Until last
saturday, when I noticed that in fact the switch with the 1.0.0.47 firmware uses only layer-2 
hashing to select the outgoing slave in a 802.3ad channel bonding. As you might have understood, 
it ruins all the efforts of both servers, since they have a constant and unique MAC address, so always the same
slave is selected to move data from the switch to any server.

Brave as I am, I download the new firmware revision (which needs a new boot image), and I remotely installs it.
And that was the start of the nightmare...

The switch _upgraded_ the configuration to the new version, but unfortunately both 802.3ad channel groups 
were not up after the restart. After enquiring I couldn't _find any valid reason_ why the peers wouldn't
form such group.

OK, so back to the previous firmware (so that at least the backup scheduled for the same night would succeed). Unfortunately, 
something I didn't think about, was that the new boot image couldn't boot the old firmware. And if it did,
I was still screwed up because it wouldn't have been possible to run the configuration since
it had been internally converted to the newer format... 

I already downgraded cisco gear, and I never had such failure... Back to the topic.

So the switch was bricked, sitting in the cabinet without switching any packets. Since we don't have any 
remote console server (and I was at home), I left the switch as is until early Monday...

On Monday, I connected my helpful [eeePC](http://eeepc.asus.com/global/index.html) (and an USB/Serial converter), 
launched [Minicom](http://en.wikipedia.org/wiki/Minicom), and connected to the switch serial console. 
I rebooted the switch, erased the config, rebooted, reloaded the config from our tftp server 
and I was back to 1.0.0.47 with both 802.3ad channel groups working... but still no layer-3 hashing...

But since I'm someone that wants to understand why things are failing, I also tried again the 
move to firmware 2.0.1.3 to see where I was wrong. And still the same result: no more channel groups, 
so back to 1.0.0.47 (because some angry users wanted to actually work that day :-))

After exchanging a few forum posts with some people on the Dell Community forum (I don't have any support for this switch),
**I was suggested to actually erase the configuration** before moving to the new firmware.

And **that did it**. It seems that the process of upgrading the configuration to the newest version is buggy
and gave a somewhat invalid configuration from which the switch was unable to recover.

In fact, the switch seems to compile the configuration in a binary form/structure it uses to talk to the hardware.
And when it upgraded the previous binary version, certainly some bits flipped somewhere and the various ports although
still in the channel groups were setup as INDIVIDUAL instead of AGGREGATABLE.

Now the switch is running with a layer-3 hash algorithm, but it doesn't seem to work fine, as if I run two parallel _netcats_ 
on 2 IP addresses on the first server, connected to two other netcats on the second server, everything goes on only one path.
I think this part needs more testing...

How would you test 802.3ad hashing?

