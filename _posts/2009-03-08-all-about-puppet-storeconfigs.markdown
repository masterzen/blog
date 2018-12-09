--- 

title: All about Puppet storeconfigs
date: 2009-03-08 20:40:47 +01:00
comments: true
wordpress_id: 21
wordpress_url: http://www.masterzen.fr/?p=21
categories: 
- Programming
- Puppet
- System Administration
- MySQL
- Ruby
tags: 
- database
- puppetmaster
- storeconfigs
- puppet
- MySQL
- performance
---
Since a long time people (including me) complained that storeconfigs was a real resource hog. Unfortunately for us,
this option is so cool and useful.

## What's storeconfigs
[Storeconfigs](http://reductivelabs.com/trac/puppet/wiki/UsingStoredConfiguration) is
a [puppetmasterd](http://reductivelabs.com/trac/puppet/wiki/PuppetExecutables#id6) 
[option](http://reductivelabs.com/trac/puppet/wiki/ConfigurationReference) that stores the nodes
actual configuration to a database. It does this by comparing the result of the last 
compilation against what is actually in the database, resource per resource, then parameter per parameter, and so on.T

he actual implementation is based on [Rails' Active Record](http://rubyonrails.org/), which is a great way to abstract 
the gory details of the database, and prototype code easily and quickly (but has a few shortcomings).

## Storeconfigs uses
The immediate use of storeconfigs is [exported resources](http://reductivelabs.com/trac/puppet/wiki/ExportedResources). Exported resources are resources which are prefixed by @@. 
Those resources are marked specially so that they can be collected on several other nodes.

A little completely dumb example speaks by itself:

``` ruby
class exporter {  
  @@file {    
    "/var/lib/puppet/nodes/$fqdn": content => "$ipaddress\n", tag => "ip"  
  }
}

node "export1.daysofwonder.com" {  
  include exporter
}

node "export2.daysofwonder.com" {  
  include exporter
}

node "collector.daysofwonder.com" {  
  File <<| tag == "ip" |>>
}
```

What does this example do?

That's simple, all the exporter nodes creates a file in /var/lib/puppet/nodes whose name is the node name and 
whose content is its primary IP address.

What is interesting is that the node "_collector.daysofwonder.com_" collects all files tagged by "_ip_", that
is all the exported files. In the end, after _exporter1, exporter2_ and _collector_ have run a compilation,
the collector host will have the /var/lib/puppet/nodes/exporter1.daysofwonder.com and 
/var/lib/puppet/nodes/exporter2.daysofwonder.com and their respective content.

Got it?

That's the perfect tool for instance to automatically:

- share/distribute public keys (ssh or openssl or other types)
- build list of hosts running some services (for monitoring)
- build configuration files which requires multiple hosts (for instance /etc/resolv.conf can be the concatenation of files exported by your dns cache hosts
- and certainly other creative use

Still there is another use, since the whole configuration of your nodes is in an RDBMS, you can use that to perform some data-mining about your hosts configuration. That's what [puppetshow](http://reductivelabs.com/trac/puppet/wiki/PuppetShow) does.

## Shortcomings
The storeconfigs issue its current incarnation (ie 0.24.7) is that it _is a slow feature_ (it usually doubles the compilation time), 
and imposes an higher load on the puppetmaster and the database engine.

For large installation it might not possible to be able to run with this feature on. There were also some reports
of high memory usage or leak with this feature on (see my recommendation about 
this [in my puppetmaster memory leak post](http://www.masterzen.fr/2009/01/19/puppet-memory-leaks-or-not/)).

## Recommendations
Here my usual puppet and storeconfigs recommendations:

- use a fairly new ruby interpreter (at least one that is _known to be memory leak free_)
- use a fairly new Rails (I'm currently using rails 2.1.0 on my master without any issues)
- use the mysql ruby connector if you use mysql (otherwise rails will use a pure ruby implementation which is reported to not be stable)
- use a powerful database engine (not sqlite), and for large deployements use a dedicated server (or cluster of servers). If you are using mysql and you want to trust your data, use InnoDB of course.
- properly tune your database engine for a mix of writes and reads (for InnoDB a properly sized buffer pool and logs is mandatory).
- make sure _your manifests are determinists_

I think the last point deserves a little bit more explanation:

I had the following schematized pattern in some of my manifests, that I took from [David Schmitt excellent modules](http://reductivelabs.com/trac/puppet/wiki/CompleteConfiguration):

``` ruby
in one class:
if defined(File["/var/lib/puppet/modules/djbdns.d/"]) {  
  warn("already defined")
} else {  
  file {
    "/var/lib/puppet/modules/djbdns.d/": ...  
  }
}

and in another class the exact same code:

if defined(File["/var/lib/puppet/modules/djbdns.d/"]) {  
  warn("already defined")
} else {  
  file {    
    "/var/lib/puppet/modules/djbdns.d/": ...  
  }
}
```

What happens is that from run to run the evaluation order could change, and the defined resource 
could be the one in the first class and another time it could be the one in the second class,
which meant the storeconfigs code had to remove the resources from the database and re-create them again.
Clearly not the best way to have less database workload :-)

## What's cooking
I [contributed for 0.24.8 a partial rewrite](http://projects.reductivelabs.com/issues/1930) of some parts 
of the storeconfigs feature to increase its performance.

My analysis is that what was slow in the feature is threefold:

1. creating **tons of Active Record objects is slow** (one object per resource parameters)
2. although the code was clearly rails optimized code (ie using association prefetching and so), there was **still a large number of read operations** for all the tags and parameters
3. there are **still a large number of writes** to the database on successive runs because the order of tags evaluation is not guaranteed.

I fixed the first two points by attacking directly the database to fetch the parameters and tags, keeping them in  hash 
instead of objects. This _saves a large number of database requests and at the same time it prevents a large number of ruby objects to be created_ 
(it should even save some memory).

The [last point was fixed](http://projects.reductivelabs.com/issues/1930) by imposing a strict
order (although not completely correct, but still better that how it was) in the way the tags are
assigned to resources.

Both patches have been merged for [0.24.8](http://projects.reductivelabs.com/versions/show/27), and some people reported
some performance improvements.

On the [Days of Wonder](http://www.daysofwonder.com) infrastructure I found that with a 562 resources node, on a tuned 
mysql database:

- 0.24.7:
```
info: Stored catalog for corp2.daysofwonder.com in 4.05 seconds
notice: Compiled catalog for corp2.daysofwonder.com in 6.31 seconds
```

- 0.24.7 with the patch:
```
info: Stored catalog for corp2.daysofwonder.com in 1.39 seconds
notice: Compiled catalog for corp2.daysofwonder.com in 3.80 second
```

That's a nice improvement, isn't it :-)

## The future?
Luke and I discussed about this, it was also discussed on the [puppet-dev list](http://groups.google.com/group/puppet-dev) 
a few times. I think that a RDBMS might not be the right storage choice for this feature, because clearly there is 
almost no random keyed access to the individual parameters of a resource (so having a table dedicated 
to parameters is of almost no use).

I know Luke's plan is to abstract the storeconfigs feature from the current implementation 
(certainly through the indirector), so that we can use different storeconfigs engines.

I also know that someone is working on a promising [CouchDB](http://couchdb.apache.org/) implementation. I myself can 
see a [memcached](http://www.danga.com/memcached/) implementation (which I'd really like to start working on). 
Maybe even the filesystem would be enough.

Of course, I'm open to any other improvements or storage engine ideas :-)
