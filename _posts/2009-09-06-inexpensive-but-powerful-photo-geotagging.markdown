---

title: Inexpensive but Powerful Photo Geotagging
date: 2009-09-06 17:31:22 +02:00
comments: true
wordpress_id: 94
wordpress_url: http://www.masterzen.fr/?p=94
category:
- Photography
tags:
- gps
- geotag
- igotu
- gpx
- macosx
- geotagging
---
It's [a long time since I blogged about photography](/2009/02/01/no-more-slides-welcome-to-our-digital-overlords/), but I'm coming back from 2 weeks vacation in Sicily armed with my Nikon D700, so it's the perfect time to talk about this hobby.

Since I sold my soul to our digital overlord (and ditched my slide scanner at the same time), I now have access to all the options digital photography can give me. And one that is very cool is [geotagging](http://en.wikipedia.org/wiki/Geotagging).

When I purchased my [D700](http://imaging.nikon.com/products/imaging/lineup/digitalcamera/slr/d700/index.htm) back in last December, I had this whole geotagging idea back in my mind. Unfortunately at that time I couldn't find any inexpensive but powerful geotagging system.

Sure you can use almost any GPS logger for this task, but the current models at that time were heavy and expensive and more directed to sports than photography.

Sure Nikon is selling the [GP-1 GPS module](http://www.nikonusa.com/Find-Your-Nikon/Product/Miscellaneous/25396/GP-1-GPS-Unit.html) you can attach on the camera, unfortunately it is expensive, large and doesn't seem to be available in France.

But a couple of month ago, my father send me a link about a damn small GPS logger called: [I got U](http://www.i-gotu.com/) GTS-120.

![I got U - GTS 120](/images/uploads/2009/09/igotu2-150x150.jpg "I got U - GTS 120")

The device is just a [GPS logger](http://en.wikipedia.org/wiki/GPS_tracking), it doesn't have any display (except a blue and red led), and is not linked to the camera in anyway (it records a position every few seconds, this interval can be customized, mine is take a point every 30s).

The thing is really cool:

- it is as small as 2 (French sized) sugar cubes and weights only 20g.
- it has a large autonomy (it covered my 2 weeks vacation with intermittent usage without charging it). You can charge it connected on a computer or with any USB charger (I'm using an ipod one).
- it can capture 65000 waypoints. The frequency of acquisition can be controlled, and the 6s default one seems a little bit fast for me. I'm using comfortably 30s.
- it is cheap, about 50 EUR in France.
- it seems to work while in the pocket :-)


The device is sold with an USB cable for charging and data access, and software. This software can be used to setup the device, display your trips, and associates photos to waypoints.

The main drawback of the system is that it is lacking a Mac OS X application. But that's not a big deal, since there's a GPL Mac OS X/Linux tool to download the waypoints called [igotu2gpx](https://launchpad.net/igotu2gpx). Once launched, this tool auto-detects the device. Then you can grab the waypoints and save them as GPX for future use.

But we've done only half of the way to geotagging the photos. Here comes another (free) tool: [GPS Photolinker](http://www.earlyinnovations.com/gpsphotolinker/) which can automatically batch geotagging tons of photos. This tool knows how to read most of the RAW photo formats, including Nikon NEF.

_Geotagging_ is done by matching the date and time of the photo (which is stored somewhere in the EXIF data) with one of the waypoint, so it works for NEF and JPG formats.

If no waypoint date and time match, the software assigns either the closest matching waypoint (up to a configurable time difference) or a linear interpolation between two consecutive waypoint. Of course you need your camera to have an accurate date and time (mine is synchronized each time I connect it to the Nikon transfer software). GPS Photolinker is able to apply a time shift if your camera clock wasn't accurately set. One nice feature of GPS Photolinker is that it fills the City and Country fields of the IPTC data section with Google Maps information (which seems to be accurate).

Here is a sample of my Sicily geotagging efforts in Smugmug:

![Geotagged photos appearing as pins in Smugmug](/images/uploads/2009/09/map.jpg "Geotagged photos appearing as pins in Smugmug")

Happy geotagging!
