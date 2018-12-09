---

title: Benchmarking Puppet Stacks
date: 2012-01-08 19:23:45
comments: true
categories:
- puppet
tags:
- puppet
- benchmark
- passenger
- mongrel
- jruby
---

I decided this week-end to try the more popular _puppet master stacks_ and benchmark them with puppet-load (which is a tool I wrote to simulate concurrent clients).

My idea was to check the common stacks and see which one would deliver the best concurrency. This article is a follow-up of my previous [post about puppet-load and puppet master benchmarking](/2010/10/18/benchmarking-puppetmaster-stacks/)

## Methodology

I decided to try the following stacks:

- _Apache_ and _Passenger_, which is the blessed stack, with MRI 1.8.7 and 1.9.2
- _Nginx_ and _Mongrel_
- _JRuby_ with minzuno


The setup is the following:

- one _m1.large_ ec2 instance as the master
- one _m1.small_ ec2 instance as the client (in the same availability zone if that matters)

To recap, m1.large instances are:

- 2 cpu with 2 virtual core each
- 8 GiB of RAM

All the benchmarks were run on the same instance couples to prevent skew in the numbers.

The master uses my own production manifests, consisting of about 100 modules. The node for which we'll compile a catalog contains 1902 resources exactly (which makes it a big catalog).

There is no storeconfigs involved at all (this was to reduce setup complexity).

The methodology is to setup the various stacks on the master instance and run puppet-load on the client instance. To ensure everything is hot on the master, a first run of the benchmark is run at full concurrency first. Then multiple run of puppet-load are performed simulating an increasing number of clients. This pre-heat phase also make sure the manifests are already parsed and no I/O is involved.

Tuning has been done as best as I could on all stacks. And care was taken for the master instance to never swap (all the benchmarks involved consumed about 4GiB of RAM or less).

## Puppet Master workload

Essentially a puppet master compiling catalog is a CPU bound process (that's not because a master speaks HTTP than its workload is a webserver workload). That means during the compilation phase of a client connection, you can be guaranteed that puppet will consume 100% of a CPU core.

Which essentially means that there is usually little benefit of using more puppet master processes than CPU cores on a server.

## A little bit of scaling math

When we want to scale a puppet master server, there is a rough computation that allows us to see how it will work.

Here are the elements of our problem:

- 2000 clients
- 30 minutes sleep interval, clients evenly distributed in time
- master with 8 CPU core and 8GiB of RAM
- our average catalog compilation is 10s

30 minutes interval means that every 30 minutes we must compile 2000 catalogs for our 2000 nodes. That leaves us with ``2000/30 = 66`` catalogs per minute. 

That's about a new client checking-in about every seconds.

Since we have 8 CPU, that means we can accommodate 8 catalogs compilation in parallel, not more (because CPU time is a finite quantity).

Since ``66/8 = 8.25``, we can accommodate _8 clients per minute_, which means each client must be serviced in less than ``60/8.25 = 7.27s``.

Since our catalogs take about 10s to compile (in my example), we're clearly in trouble and we would need to either add more master servers or increase our client sleep time (or not compile catalogs, but that's another story).

## Results

### Comparing our stacks

Let's first compare our favorite stacks for an increasing concurrent clients number (increasing concurrency).

For setups that requires a fixed number of workers (_Passenger_, _Mongrel_) those were setup with 25 puppet master workers. This was fitting in the available RAM.

For _JRuby_, I had to use the at the time of writing _jruby-head_ because of a bug in 1.6.5.1. I also had to comment out the Puppet execution system (in ``lib/puppet/util.rb``). 

Normally this sub-system is in use only on clients, but when the master loads the types it knows for validation, it also autoloads the providers. Those are checking if some support commands are available by trying to execute them (yes I'm talking to you rpm and yum providers). 

I also had to comment out when puppet tries to become the puppet user, because that's not supported under _JRuby_.

_JRuby_ was run with Sun java 1.6.0_26, so it couldn't benefit from the invokedynamic work that went into Java 1.7. I fully expect this feature to improve the performances dramatically.

The main metric I'm using to compare stacks is the **TPS** (_transaction per seconds_). This is in fact the number of catalogs a master stack can compile in one second. **The higher the better**. Since compiling a catalog on our server takes about 12s, we have TPS numbers less than 1.

Here are the main results:

![Puppet Master Stack / Catalog compiled per Seconds](/images/uploads/2012/01/tps.png "Puppet stack TPS")

And, here is the failure rate:

![Puppet Master Stack / Failure rate](/images/uploads/2012/01/failures.png "Failure rate")

First notice that some of the stack exhibited failures at high concurrency. The errors I could observe were clients timeouts., even tough I configured a large client side timeout (around 10 minutes). This is what happens when too many clients connect at the same time. Everything slows down until the client times out.

### Fairness

In this graph, I plotted the min, average, median and max time of compilation for a concurrency of 16 clients.

![Puppet Master Stack / fairness](/images/uploads/2012/01/fairness.png "Fairness")

Of course, the better is when min and max are almost the same.

### Digging into the number of workers

For the stacks that supports a configurable number of workers (mongrel and passenger), I wanted to check what impact it could have. I strongly believe that there's no reason to use a large number (compared to I/O bound workloads).

![Puppet Master Stack / Worker # influence](/images/uploads/2012/01/workers.png "Workers # influence")

## Conclusions

Beside being fun this project shows why Passenger is still the best stack to run Puppet. JRuby shows some great hopes, but I had to massage the Puppet codebase to make it run (I might publish the patches later).

That'd would be really awesome if we could settle on a corpus of manifests to allow comparing benchmark results between Puppet users. Anyone want to try to fix this?


