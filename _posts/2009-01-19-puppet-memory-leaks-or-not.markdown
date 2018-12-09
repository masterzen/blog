--- 

title: Puppet Memory Leaks... Or not...
date: 2009-01-19 23:03:17 +01:00
comments: true
wordpress_id: 14
wordpress_url: http://www.masterzen.fr/?p=14
categories: 
- Puppet
- System Administration
- Ruby
- Programming
tags: 
- dtrace
- gdb
- storeconfigs
- memory leak
- rails
- puppet
- Ruby
- MySQL
- bleak house
---
From time to time we get some complaints about so-called [Puppet](http://reductivelabs.com/trac/puppet) memory leaks 
either on [#puppet](http://reductivelabs.com/trac/puppet/wiki/IrcChannel), 
on the [puppet-user list ](http://groups.google.com/group/puppet-users)
or in the [Puppet redmine](http://projects.reductivelabs.com/projects/puppet/issues).

I tried hard to reproduce the issue on the [Days of Wonder](http://www.daysofwonder.com) servers (mostly up-to-date debian), 
but never could. Starting from there I tried to gather from the various people I talked to on various channels what could 
be the cause, if they solved it and how.

You also can be sure **there are no memory leaks in the Puppet source code**. All of the identified memory leaks are either 
_not memory leaks per-se_ or are _caused by an out of puppet control code base_ (ruby itself or a library).

## Watch your Ruby

It is known that there are some ruby versions (around 1.8.5 and 1.8.6) exhibiting some leaks of some sort. 
This is especially true for RHEL 4 and 5 versions (and some Fedora ones too), as I found with the help of one Puppet user, 
[or as others found](http://projects.reductivelabs.com/issues/show/1480).

Upgrading Ruby to [1.8.7-pl72](ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz) either from source 
or any repositories is usually enough to fix it.

## Storeconfigs and MySQL

I also encountered some people that told me that [storeconfigs](http://reductivelabs.com/trac/puppet/wiki/UsingStoredConfiguration) 
with MySQL but [without the real ruby-mysql gem](http://reductivelabs.com/trac/puppet/wiki/UsingStoredConfiguration#id2), 
lead to some increasing memory footprint for their puppetmaster.

## Storeconfigs and Rails < 2.1

It seems also to be a common advice to use Rails 2.1 if you use storeconfigs. 
I don't know if Puppet uses this, but it seems that [nested includes leaks in rails 2.0](http://www.movesonrails.com/articles/2008/07/02/nested-include-has-major-memory-leak-rails-2-0-1).

## Is it really a leak?

The previous items I outlined above are real leaks. Some people (including myself) encountered a different issue: 
the puppetmaster is consuming lots of memory while doing file transfer to the clients.

In fact, up to _Puppet 0.25_ (not yet released at this time), Puppet is using [XMLRPC](http://www.xmlrpc.com/) as its communication protocol. 
Unfortunately this is not a transfer protocol, it is a [Remote Procedure Call protocol](http://en.wikipedia.org/wiki/Remote_procedure_call). 
It means that to transfer binary files, _Puppet_ has to load the _whole file_ in memory, 
and then it escapes its content (same escaping as URL, which means every byte outside of 32-127 will take 3 bytes). 
Usually that means the master has to allocate roughly 2.5 times the size of the current transferred file. 

Puppet 0.25 will use REST (so native HTTP) to transfer files, which will bring speed and streaming to file serving.
Hopefully, if the [Garbage Collector](http://en.wikipedia.org/wiki/Garbage_collection_(computer_science)) has a chance 
to trigger (because your ruby interpreter is not too much loaded), it will de-allocate all these memory used for files. 

If you are not so lucky, the ruby interpreter don't have time to run a full garbage cycle, and the memory usage grows.
Some people running high-load puppetmaster have _separated their file serving puppetmaster_ from their config serving puppetmaster to 
alleviate this issue.

Also, if like me you are using file recursive copy, you might encounter [Bug #1469 File recursion with a remote source should not recurse locally](http://projects.reductivelabs.com/issues/show/1469).

## I still have a leak you didn't explain

Here is how you can find leaks in a ruby application:

- On [DTrace](http://www.sun.com/bigadmin/content/dtrace/) enabled platform, and with the [DTrace Toolkit](http://opensolaris.org/os/community/dtrace/dtracetoolkit/) Ruby Script you can have a better view of the generated/freed objects.
- Using [GDB to inspect a live Ruby process](http://eigenclass.org/hiki.rb?ruby+live+process+introspection)
- Using [Ruby Bleak House,](http://blog.evanweaver.com/files/doc/fauna/bleak_house/files/README.html) this is a ruby gem which builds a specially patched ruby interpreter that can print leaked objects

I tried the three aforementioned techniques, and found that the GDB trick is the easier one to use and setup.

## Another Ruby?
There's also something that I think hasn't been tried yet: running Puppet under a different Ruby interpreter 
(we'd say Virtual Machine in this case). For instance [JRuby](http://jruby.codehaus.org/) is running on top 
of the Java Virtual Machine which has more than 14 years of Garbage Collection development behind it.
You also can be sure than a different Ruby interpreter won't have the same bug or memory leak as the 
regular one (the so called Matz Ruby interpreter from the name of his author).

There are some nice Ruby VM under development right now, and I'm sure I'll blog about using Puppet on some of them soon :-)
