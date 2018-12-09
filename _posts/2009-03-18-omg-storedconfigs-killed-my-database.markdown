--- 

title: OMG!! storeconfigs killed my database!
date: 2009-03-18 23:42:21 +01:00
comments: true
wordpress_id: 22
wordpress_url: http://www.masterzen.fr/?p=22
categories: 
- MySQL
- System Administration
- Puppet
tags: 
- MySQL
- puppet
- storeconfigs
- InnoDB
- tuning
- storedconfigs
---
When I wrote [my previous post titled all about storedconfigs](http://www.masterzen.fr/2009/03/08/all-about-puppet-storeconfigs/), I was pretty confident I explained everything I could about [storedconfigs](http://reductivelabs.com/trac/puppet/wiki/UsingStoredConfiguration)... I was _wrong_ of course :-)

A couple of days ago, I was helping some [USG admins](http://www.usg.edu/) who were facing an interesting issue. Interesting for me, but I don't think they'd share my views on this, as their servers were melting down under the database load.But first let me explain the issue.

## The issue
The thing is that when a client checks in to get its configuration, the _puppetmaster_ compiles its configuration to a digestible format and returns it. This operation is the process of transforming the AST built by parsing the manifests to what is called the _catalog_ in Puppet. This is this catalog (which in fact is a graph of resources) which is later played by the client.

When the compilation process is over, and _if storedconfigs_ is enabled on the master, the master connects to the RDBMS, and retrieves all the resources, parameters, tags and facts. Those, if any, are compared to what has just been compiled, and if some resources differs (by value/content, or if there are some missing or new ones), they get written to the database.

Pretty straightforward, isn't it?

As you can see, this process is synchronous and while the master processes the _storedconfigs_ operations, it doesn't serve anybody else.

Now, imagine you have a large site (ie hundreds of puppetd clients), and you decide to turn on storedconfigs. All the clients checking in will see their current configuration stored in the database.

Unfortunately the first run of _storedconfigs_ for a client, the database is empty, so the puppetmaster has to send all the information to the RDBMS which in turns as to write it to the disks. Of course on subsequent runs only what is modified needs to reach the RDBMS which is much less than the first time (provided you are running [0.24.8 ](http://projects.reductivelabs.com/versions/show/27)or applied my [patch](http://projects.reductivelabs.com/issues/1930)).

But if your RDBMS is not correctly setup or not sized for so much _concurrent write load_, the _storedconfigs_ process will take time. During this time this master is pinned to the database and can't serve clients. So the immediate effect is that new clients checking in will see timeouts, load will rise, and so on.

## The database
If you are in the aforementioned scenario you must be sure your RDBMS hardware is properly sized for this peak load, and that your database is properly tuned.I'll soon give some generic MySQL tuning advices to let MySQL handle the load, but remember those are generic so YMMV.### Size the I/O subsystem

What people usually forget is that disk (ie those with rotating plates, not SSDs) have a maximum number of I/O operations per seconds. This value is for professional high-end disks about 250 IOP/s.

Now, to simplify, let's say your average puppet client has 500 resources with an average of 4 parameters each. That means the master will have to perform at least 500 * 4 + 500 = 2500 writes to the database (that's naive since there are indices to modify, and transactions can be grouped, etc.. but you see the point).

Add to this the tags, hmm let's say an average of 4 tags per resources, and we have 500 * 4 + 500 + 500 * 4 = 4500 writes to perform to store the configuration of a given host.

Now remember our 250 IOP/s, how many seconds does the disk need to performs 4500 writes?The answer is **18s**!! Which is a high value. During this time you can't do anything else. Now add concurrency to the mix, and imagine what that means.

Of course this supposes we have to wait for the disk to have finished (ie synchronous writing), but  in fact that's pretty how RDBMS are working if you really want to trust your data.So the result is that if you want a fast RDBMS you must be ready to pay for an expensive I/O subsystem.

### Size the I/O subsystem
That's certainly the most important part of your server.

You need:

- **fast disks** (15k RPM, because they is a real latency benefit compared to 10k )
- the **more spindle possible** grouped in a sane RAID array like **RAID10**. Please forget RAID5 if you want your data to be safe (and fast writes). I saw too much horror stories with RAID5. I should really join the [BAARF](http://www.baarf.com/).
- a **Battery Backed RAID Cache unit** (that will absorb the fsyncs gracefully).
- Tune the RAID for the largest stripe size. Remove the RAID read cache if possible (innodb will take care of the READ cache with the innodb buffer pool).

If you don't have this, _do not even think turning on storedconfigs_ for a large site.### Size the RDBMS server
Of course other things matters. If the database can fit in RAM (the best if you don't want to be I/O bound), then you obviously need RAM. Preferably [ECC](http://en.wikipedia.org/wiki/Dynamic_random_access_memory#Errors_and_error_correction) [Registered](http://en.wikipedia.org/wiki/Registered_memory) RAM. Use 64 bits hardware with a 64 bits OS.Then you need some CPU. Nowadays they're cheap, but beware of InnoDB scaling issues on multi-core/multi-CPU systems (see below).

### Tune the database configuration
Here is a checklist on how to tune MySQL for a mostly write load:

#### InnoDB of course
For concurrency, stability and durability reasons [InnoDB](http://en.wikipedia.org/wiki/InnoDB) is mandatory. MyISAM is at best usable for READ workload but suffers concurrency issues so it is a no-no for our topic

#### Tuned InnoDB
The default InnoDB settings are tailored to very small 10 years old servers...

Things to look to:

- **innodb_buffer_pool_size**. Usual advice says 70% to 80% of physical RAM of the server if MySQL is the only running application. I'd say that it depends on the size of the database. If you know you'll store only a few MiB, no need to allocate 2 GiB :-). More information with this[ useful and intersting blog post from Percona guys](http://www.mysqlperformanceblog.com/2006/09/29/what-to-tune-in-mysql-server-after-installation/).
- **innodb_log_file_size**. We want those to be the largest we can to ease the mostly write log we have. Once all the clients will be stored in the database we'll reduce this to a something lower. The trade-off with large logs is the recovery time in case of crash. It isn't uncommon to see several hundreds of MiB, or even GiB.
- **innodb_flush_method = O_DIRECT** on Linux. This is to prevent the OS to cache the innodb_buffer_pool content (thus ending with a double cache).****
- **innodb_flush_log_at_trx_commit=2**. If your MySQL server doesn't have any other use than for storedconfigs or you don't care about the D in ACID. Otherwise use 0. It is also possible to temporarily change it to 2, and then move back to 0 when all clients have their configs stored.
- **transaction-isolation=READ-COMMITTED.** This one can help also, although I never tested it myself

#### Patch MySQL
The fine people at Percona or Ourdelta produces some patched builds of MySQL that removes some of the MySQL InnoDB scalability issues. This is more important on high concurrency workload on multi-core/multi-cpu systems.

It can also be good to run MySQL with [Google's perftools TCMalloc](http://goog-perftools.sourceforge.net/doc/tcmalloc.html). TCMalloc is a memory allocator which scales way better than the Glibc one.## On the Puppet side

The immediate and most straightforward idea is to **limit the number of clients** that can check in at the same time. This can be done by disabling puppetd on each client (_puppetd --disable_), blocking network access, or any other creative mean...

When all the active hosts have checked in, you can then enable the other ones. This can be done hundreds of hosts at a time, until all hosts have a configuration stored.

Another solution is to direct some hosts to a special _puppetmaster_ with _storeconfigs_ on (the regular one still has storeconfigs disabled), by playing with DNS or by configuration, whatever is simplest in your environment. Once those hosts have their config stored, move them back to their regular puppetmaster and move newer hosts there.Since that's completely manual, it might be unpractical for you, but that's the simplest method.

## And after that?
As long as your manifests are only slightly changing, subsequent runs will see only a really limited database activity (if you run a puppetmaster >= 0.24.8). That means the tuning we did earlier can be undone (for instance you can lower the innodb_log_file_size for instance, and adjust the innodb_buffer_pool_size to the size of the hot set).

But still storeconfigs can double your compilation time. If you are already at the limit compared to the number of hosts, you might see some client timeouts.

## The Future
Today [Luke](http://madstop.com/) announced on the [puppet-dev list](http://groups.google.com/group/puppet-dev) that they were working on a _queuing system_ to defer storeconfigs and smooth out the load by spreading it on a longer time. But still, tuning the database is important.The idea is to offload the _storeconfigs_ to another daemon which is hooked behind a queuing system. After the compilation the _puppetmaster_ queues the catalog, where it will be unqueued by the puppet queue daemon which will in turn execute the _storedconfigs_ process.

I don't know the ETA for this interesting feature, but meanwhile I hope the tips I provided here can be of any help to anyone :-)

Stay tuned for more puppet stories!
