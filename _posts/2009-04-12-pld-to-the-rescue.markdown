---

title: PLD to the rescue!
date: 2009-04-12 17:36:57 +02:00
comments: true
wordpress_id: 23
wordpress_url: http://www.masterzen.fr/?p=23
categories:
- System Administration
- War stories
tags:
- grml
- opengear
- console server
- console
- rescue
- pld rescue
- netboot
- sysadmin
- zsh
---
There is something I used to hate to do. And I think all admins also hate to do that.

It's when you need to reboot a server on a rescue environment to perform an administration task (i.e. fixing unbootable servers, fixing crashed root filesystems, and so on).

The commonly found problems with rescue environment are:

- they're not always remotely usable
- they're not always updated to your specific kernel version or tool
- they can be difficult to use
- some are CD or DVD only (no netboot, no usb keys...)
- they don't recognize your dumb azerty keyboard (argh, too much time spent looking for / or .)
OK, so a long time ago, I had a crashed server refusing to start on a reboot, and I had to chose a rescue environment for linux servers, other than booting on the Debian CD once again.

That's how I discovered [PLD Linux rescue CD](http://rescuecd.pld-linux.org/):
[![PLD Rescue](/images/uploads/2009/04/rescue.png "PLD Rescue")](http://www.masterzen.fr/wp-content/uploads/2009/04/rescue.png)


and [GRML:](http://grml.org/)

[![GRML](/images/uploads/2009/04/logo.png "GRML")](http://www.masterzen.fr/wp-content/uploads/2009/04/logo.png)


My heart still goes to _PLD rescue_ (because it's really light), but I must admit that _GRML_ has a [really good zsh configuration](http://grml.org/zsh/) (I even used some of their configuration ideas for my day to day zsh).

On that subject, if you don't use [zsh](http://www.zsh.org/) or don't even know it and still want to qualify as a knowledgeable Unix admin, then **please try it** (preferably with GRML so that you'll have an idea of what's possible, and they even have [a good documentation](http://grml.org/zsh/grml-zsh-refcard.pdf "GRML szh quick ref card (PDF)")), another solution is to buy of course this really good book: "[From Bash to Z Shell: Conquering the Command Line](http://www.bash2zsh.com/)"

That makes me think I should do a whole blog post on zsh.

OK, so let's go back to our sheep (yes that's a literally French translated expression, so I don't expect anyone to grasp the funny part except the occasional French guys reading me :-)).

So what's so good about PLD Rescue:

- it supports serial console (and that's invaluable if you like me use a console server, and you should)
- it can be booted:
 - [through PXE](http://www.maven.pl/2007/01/13/pxe-remote-boot-for-your-homework-lab/)
 - with an [USB key](http://rescuecd.pld-linux.org/download/2009-02-21/USB.txt)
 - with a [CD/DVD](http://rescuecd.pld-linux.org/download/2009-02-21/x86_and_x86_64/)
 - directly with [an image on an harddrive](http://www.maven.pl/2007/08/30/booting-pld-rescuecd-from-lilo/)
- it's fully packed with only sysadmin tools - that's the perfect sysadmin swiss-knife
- it always stay up to date (currently kernel 2.6.28)
- it works on x86 and amd64 servers

So my basic usage is to have a PXE netboot environment in our remote colocation, a console server (it is a real damn good [Opengear CM4116](http://www.opengear.com/product-cm4116.html)).

With this setup I can netboot remotely any server to a _PLD Rescue_ image with serial support, and then rescue my servers without going to the datacenter (it's not that it is far from home or the office, but at 3AM, you don't usually want to go out).

If you have a preferred rescue setup, please share it!
