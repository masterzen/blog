--- 

title: More Puppet Offloading
date: 2010-03-21 16:56:58 +01:00
comments: true
wordpress_id: 186
wordpress_url: http://www.masterzen.fr/?p=186
categories: 
- Programming
- Nginx
- Puppet
- System Administration
- Ruby
tags: 
- offloading
- Nginx
- puppetmaster
- puppet
- cache
---
[Puppet](http://reductivelabs.com/products/puppet/) really shines at configuration management, but there are some things it is not good at, for instance file sourcing of large files, or managing deep hierarchies.

Fortunately, most of this efficiency issues will be addressed in a subsequent major version (thanks to [some of](http://projects.reductivelabs.com/issues/3396) [my patches](http://projects.reductivelabs.com/issues/2929) and other refactorings).

Meanwhile it is interesting to work-around those bugs. Since most of us are running our masters as part of a more complete stack and not isolated, we can leverage the power of this stack to address some of the issues.

In this article, I'll expose two techniques to help your overloaded masters to serve more and more clients.

## Offloading file sourcing

I already talked about offloading file sourcing in a [previous blog post about puppet memory consumption](http://www.masterzen.fr/2010/01/28/puppet-memory-usage-not-a-fatality/). Here the idea is to prevent our puppetmasters to read the whole content of files in memory at once to serve them. Most of the installation of puppetmasterd out there are behind an http reverse proxy of some sort (ie Apache or Nginx).

The idea is that file serving is an activity that a small static server is better placed to do than puppet itself (that might change when [#3373](http://projects.reductivelabs.com/issues/3373) will be fully addressed). Note: I produced [an experimental patch pending review](http://groups.google.com/group/puppet-dev/t/f9ffe87357c2ba38) to stream puppet file sourcing on the client side, which this tip doesn't address.

So I did implement this in [Nginx](http://www.nginx.org) (which is my favorite http server of course, but that can be ported to any other webserver quite easily, which is an exercise left to the reader):

{% gist 339342 %}

And if you use multiple module paths (for instance to separate common modules to other modules), it is still possible to use this trick with some use of [nginx try_files](http://wiki.nginx.org/NginxHttpCoreModule#try_files) directive.

The try_files directive allows puppet to try several physical path (the first matching one will be served), and if none match you can use the generic location that proxies to the master which certainly will know what to do.

Something that can be useful would be to create a small script to generate the nginx config from your fileserver.conf and puppet.conf. Since mine is pretty easy, I did it manually.

## Optimize Catalog Compilation

The normal process of puppet is to contact the _puppetmaster_ at some time interval asking for a catalog. The catalog is a byproduct of the compilation of the parsed manifests in which are injected the node facts. This operation takes some times depending on the manifest complexity and the server capacity or current load.

Most of the time an host requires a catalog while the _manifests didn't change at all_. In my own infrastructure I rarely change my manifests once a kind of host become stable (I might do a change every week at most when in production).

Since 0.25, puppet is now fully [RESTful](http://en.wikipedia.org/wiki/Representational_State_Transfer), that means to get a catalog _puppetd_ contacts the master under its SSL protected links and asks for this url:

{% gist 339348 %}

In return the puppetmaster responds by a json-encoded catalog.
The actual compilation of a catalog for one of my largest host takes about 4s (excluding storeconfigs). During this 4s one ruby thread inside the master is using the CPU. And this is done once every 30 minutes, even if the manifests don't change.

What if we could compile only when something changes? This would really free our masters!

Since puppet uses HTTP, it is easy to add a front-most HTTP cache in front of our master to actually cache the catalog the first time it is compiled and serve this one on the subsequent requests.

Although we can do it with any HTTP Cache (ie Varnish), this is really easy to add this with Nginx (which is already running in my own stack):

{% gist 339353 %}

Puppet currently doesn't return any http caching headers (ie Cache-Control or Expires), so we use nginx ability to cache despite it (see proxy_cache_valid). Of course I have a [custom puppet branch](http://github.com/masterzen/puppet/tree/features/http-catalog-cache) that introduces a new parameter called _--catalog_ttl_ which allows puppet to set those cache headers.

One thing to note is that the _cache expiration won't coincide with when you change your manifests_. So we need some ways to purge the cache when you deploy new manifests.

With Nginx this can be done with:

- removing the nginx cache directory: rm -rf /var/cache/nginx/cache &amp;&amp; killall -HUP nginx
- selectively purge with: the [Nginx proxy cache purge module](http://github.com/FRiCKLE/ngx_cache_purge).


It's easy to actually add one of those methods to any _svn hook_ or _git post-receive hook_ so that deploying manifests actually purge the cache.

Note: I think that ReductiveLabs has some plan to add catalog compilation caching directly to Puppet (which would make sense). This method is the way to go before this features gets added to Puppet. I have no doubt that caching inside Puppet will be much better than outside caching, mainly because Puppet would be able to expire the cache when the manifests change.

There a few caveats to note:

- any host with a valid certificate can request another cached catalog, unlike with the normal puppetmaster which makes sure to serve catalogs only to the correct host. It's something that can be a problem for some configurations
- if your manifests rely on "dynamic" facts (like uptime or free memory), obviously you shouldn't cache the catalog at all.
- the above nginx configuration doesn't include the facts as part of the cache key. That means the catalog won't be re-generated when any facts change and the cached catalog will always be served. If that's an issue, you need to purge the cache when the host itself change.


I should also mention that caching is certainly not the panacea of reducing the master load.

Some other people are using clever methods to smooth out master load. One notable example is the [MCollective puppet scheduler](http://www.devco.net/archives/2010/03/17/scheduling_puppet_with_mcollective.php), [R.I Pienaar](http://twitter.com/ripienaar) has written. In essence he wrote a _puppet run scheduler_ running on top of [MCollective](http://code.google.com/p/mcollective/) that schedule puppet runs (triggered through MCollective) when the master load is appropriate. This allows for the best use of the host running the master.

If you also have some tricks or tips for running puppet, do not hesitate to contact me (I'm masterzen on freenode's #puppet or [@_masterzen_](http://twitter.com/_masterzen_) on twitter).

