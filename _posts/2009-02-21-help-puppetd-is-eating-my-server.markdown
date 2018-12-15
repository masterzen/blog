--- 

title: Help! Puppetd is eating my server!
date: 2009-02-21 17:18:17 +01:00
comments: true
wordpress_id: 20
wordpress_url: http://www.masterzen.fr/?p=20
category: 
- System Administration
- Monitoring
- Puppet
tags: 
- puppet
- War stories
- checksum
- recursive
- memory
- cpu
---
This seems to be recurrent this last 3 or 4 days with a few [#puppet](irc://irc.freenode.net/puppet), 
[redmine](http://projects.reductivelabs.com/projects/puppet/issues) or 
[puppet-user](http://groups.google.com/group/puppet-users) requests, asking about why _puppetd_ 
is consuming so much CPU and/or memory.

While I don't have a definitive answer about why it could happen (hey all software components have bugs), 
I think **it is important to at least know how to see what happens**. I even include some common issues I
myself have observed.

## Know your puppetd
I mean, know what is _puppetd_ doing. That's easy, disable _puppetd_ on the host where you have an issue, 
and try to run it manually in debug mode. I'm really astonished that almost nobody 
tries a debug run before complaining that something doesn't work :-)

```
% puppetd --disable
% puppetd --test --debug --trace
... full output on the console ...
```

At the same time, monitor the CPU usage and look at the debug entries when most of the CPU is consumed.

If nothing is printed at this same moment, and it still uses CPU, CTRL-C the process, maybe it will print a useful stack 
trace that will help you (or us) understand what happens.

With this you will certainly catch things you didn't intend (see below computing checksums when it is not necessary).

## Inspect your ruby interpreter
I already mentioned this tip 
[in my puppetmaster memory leak post a month ago](http://www.masterzen.fr/2009/01/19/puppet-memory-leaks-or-not/). 
You can't imagine how much useful information you can get with this tool.

Install as [explained in the original article ](http://eigenclass.org/hiki.rb?ruby+live+process+introspection)
the [ruby file](http://eigenclass.org/hiki.rb?c=plugin;plugin=attach_download;p=ruby+live+process+introspection;file_name=ruby) 
into ~/.gdb/ruby, copy the following into your ~/.gdbinit:

```
define session-ruby
source ~/.gdb/ruby
end
```

Here I'm going to show how to do this with a _puppetmasterd_, but it is exactly the same thing with puppetd.

Basically, the idea is **to attach gdb to the puppet process**, halt it and look to the current stack trace:

```
% ps auxgww | grep puppetdpuppet
   28602  2.0  8.9 275508 184492 pts/3   Sl+  Feb19  65:25 ruby /usr/bin/puppetmasterd --debug
% gdb /usr/bin/ruby
GNU gdb 6.8-debian
Copyright (C) 2008 Free Software Foundation, Inc....
(gdb) session-ruby
(gdb) attach 28602
Attaching to program: /usr/bin/ruby, process 28602...
```

Now our _gdb_ is attached to our ruby interpreter.

Lets see where we stopped:
```
(gdb) rb_backtrace
$3 = 34
```

Note: the output is displayed by default on the stdout/stderr of the attached process,
so in our case my puppetmasterd. Going to the terminal where it
runs (actually the [screen](http://www.gnu.org/software/screen/)):
```
...
        from /usr/lib/ruby/1.8/webrick/server.rb:91:in `select'
        from /usr/lib/ruby/1.8/webrick/server.rb:91:in `start'
        from /usr/lib/ruby/1.8/webrick/server.rb:23:in `start'
        from /usr/lib/ruby/1.8/webrick/server.rb:82:in `start'
        from /usr/lib/ruby/1.8/puppet.rb:293:in `start'
        from /usr/lib/ruby/1.8/puppet.rb:144:in `newthread'
        from /usr/lib/ruby/1.8/puppet.rb:143:in `initialize'
        from /usr/lib/ruby/1.8/puppet.rb:143:in `new'
        from /usr/lib/ruby/1.8/puppet.rb:143:in `newthread'
        from /usr/lib/ruby/1.8/puppet.rb:291:in `start'
        from /usr/lib/ruby/1.8/puppet.rb:290:in `each'
        from /usr/lib/ruby/1.8/puppet.rb:290:in `start'
        from /usr/sbin/puppetmasterd:285
```

It works!
It is now easy to see what _puppetd_ is doing:

1. introspect your running and eating puppetd
2. stop it (issue CTRL-C in gdb)
3. rb_backtrace, copy the backtrace in a file
4. issue 'continue' in gdb to let the process run again
5. go to 2. several times

Examining the stack traces should give you hints (or us) to what your _puppetd_ is doing at this moment.

## Possible causes of puppetd CPU consumption
### A potential bug
You might have encountered a bug. Please report it in [Puppet redmine](http://projects.reductivelabs.com/projects/puppet/issues), and **enclose all** the useful information you gathered by following the two points above.

### A recursive file resource with checksum on
That's the usual suspect, and one I encountered myself.

Let's say you have something like this in your manifest:

``` ruby
File { checksum => md5 }
...
file {  "/path/to/so/many/files":
    owner => myself, mode => 0644, recurse => true
}
```

What does that mean?

You're telling puppet that **every file resource should compute checksum**, and you have a recursive file operation
managing owner and mode. What _puppetd_ will do is to _traverse_ the whole '/path/to/so/many/files' 
and happily manage them changing owner and mode when needed.

What you might have forgotten, is that you requested checksum to be [MD5](http://en.wikipedia.org/wiki/MD5), 
so _puppetd_ instead of only doing a bunch of stat(3) on your 
files **will also compute MD5 sums of their content.**
If you have _tons of files in this hierarchy_ this can take quite some time. Since checksums are cached,
it can also take quite some memory.

How to solve this issue:

``` ruby
File { checksum => md5 }
...
file {  
  "/path/to/so/many/files":
      owner => myself, mode => 0644, recurse => true, checksum => undef
}
```

Sometimes, it isn't possible to solve this issue, if your file {} resource is a 
retrieve file (ie there is a source parameter), because you need to have checksum 
to manage the files. In this case, just byte the bullet, change the checksum to mtime, 
limit recursion or wait for my fix of [Puppet bug #1469](http://projects.reductivelabs.com/issues/1469).

### Simply no reason
Actually it is in your interest that puppetd is taking 100% of CPU while applying the 
configuration the puppetmaster has given. That just means it'll do its job faster than if it was consuming 10% of CPU :-)

I mean, _puppetd_ has a fixed amount of things to perform, some are CPU bound, some are I/O bound 
(actually most are I/O bound), so it is perfectly normal that it takes wall clock time and consume
resources to play your manifests.

What is not normal is consuming CPU or memory between configuration run. But you already know how to diagnose 
such issues if you read the start of this post :-)

## Conclusion
Not all resource consumption are bad.
We're all dreaming of a faster _puppetd_.

And at this subject, I think it should be possible (provided ruby supports native thread (maybe a task for JRuby)) 
to apply the catalog in a multi-threaded way. I never really thought about this (I mean technically), but I don't 
see why it couldn't be possible. That would allow puppetd to do several I/O bound operations in 
parallel (like installing packages and managing files at the same time).
