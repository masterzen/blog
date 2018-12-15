--- 

title: Puppet Memory Usage - not a fatality
date: 2010-01-28 22:43:33 +01:00
comments: true
wordpress_id: 168
wordpress_url: http://www.masterzen.fr/?p=168
category: 
- Programming
- Nginx
- Puppet
- System Administration
- Ruby
tags: 
- json
- REST
- heap
- allocator
- file serving
- memory hog
- memory consumption
- Nginx
- jruby
- memory
- puppet
- Ruby
- YAML
---
As every reader of this blog certainly know, I'm a big fan of [Puppet,](http://reductivelabs.com/products/) using it in production on [Days of Wonder](http://www.daysofwonder.com) servers, up to the point I used to contribute regularly bug fixes and new features (not that I stopped, it's just that my spare time is a scarce resource nowadays).

Still, I think there are some issues in term of scalability or resource consumption (CPU or memory), for which we can find some workarounds or even fixes. Those issues are not a symptom bad programming or bad design. No, most of the issues come either from ruby itself or some random library issues.

Let's review the things I have been thinking about lately.

## Memory consumption

This is by far one of the most seen issues both on the client side and the server side. I've mainly seen this problem on the client side, up to the point that most people recommend running puppetd as cronjobs, instead of being a long lived process.

### Ruby allocator

All boils down to the ruby (at least the the MRI 1.8.x version) allocator. This is the part in the ruby interpreter that deals with memory allocations. Like in many dynamic languages, the allocator manages a memory pool that is called a[ heap](http://en.wikipedia.org/wiki/Dynamic_memory_allocation). And like some other languages (among them Java), this heap can **never shrink and always grows** when more memory is needed. This is done this way because it is simpler and way faster. Usually applications ends using their nominal part of memory and no more memory has to be allocated by the kernel to the process, which gives faster applications.

The problem is that if the application needs transiently a high amount of memory that will be trashed a couple of millisecond after, the process will pay this penalty all its life, even though say 80% of the memory used by the process is free but not reclaimed by the OS.

_And it's even worst_. The ruby interpreter when it grows the heap, instead of allocating bytes per bytes (which would be really slow) does this by chunk. The whole question is what is the proper size of a chunk?

In the default implementation of MRI 1.8.x, a chunk is the size of the previous heap times 1.8. That means at worst a ruby process might end up allocating 1.8 times more than what it really needs at a given time. (This is a gross simplification, read the code if you want to know more).

### Yes but what happens in Puppet?

So how does it apply to _puppetd_?

It's easy, _puppetd_ uses memory for two things (beside maintaining some core data to be able to run):

1. the **catalog** (which contains all resources, along with all templates) as shipped by the _puppetmaster_ (i.e. serialized) and live as ruby objects.
2. the **content of the sourced** files (one at a time, so it's the biggest transmitted file that imposes it's high watermark for _puppetd_). Of course this is still better than in 0.24 where the content was transmitted encoded in XMLRPC adding the penalty of escaping everything...


Hopefully, **nobody distributes large files with Puppet :-)** If you're tempted to do so, see below...

But again there's more, as _Peter Meier_ (known as duritong in the community) [discovered a couple of month ago](http://groups.google.com/group/puppet-dev/browse_thread/thread/17e901f2613b9c27/552469109dac1f91?lnk=gst&q=+Possible+workaround+for+%232824#552469109dac1f91): when _puppetd_ gets its _catalog_ (which by the way is transmitted in [json](http://www.json.org/) nowadays), it also stores it as a local cache to be able to run if it can't contact the master for a subsequent run. This operation is done by unserializing the catalog from json to ruby live objects, and then serializing the laters to [YAML](http://www.yaml.org/). Beside the **evident loss of time** to do that on large catalog, YAML is a real memory hog. Peter's experience showed that about 200MB of live memory his _puppetd_ process was using came from this final serialization!

So I had the following idea: why not store the serialized version of the catalog (the json one) since we already have it in a serialized form when we receive it from the master (it's a little bit more complex than that of course). This way no need to serialize it again in YAML. This is what [ticket #2892 is all about.](http://projects.reductivelabs.com/issues/2892) [Luke](http://www.madstop.com/) is committed to have this enhancement in Rowlf, so there's good hope!

### Some puppet solutions?

So what can we do to help puppet not consume that many memory?

In _theory we could play on several factors_:

- **Transmit smaller catalogs**. For instance get rid of all those templates you love (ok that's not a solution)
- Stream the serialization/deserialization with something like [Yajl-Ruby](http://github.com/brianmario/yajl-ruby)
- Use another **ruby interpreter with a better allocator** (like for instance JRuby)
- Use a **different constant for resizing the heap** (ie replace this 1.8 by 1.0 or less on line 410 of gc.c). This can be done easily when using Rails machine GC patches or Ruby Enterprise Edition, in which case setting the environment variable  **<tt>RUBY_HEAP_SLOTS_GROWTH_FACTOR</tt>** is enough. Check the [documentation for more information](http://www.rubyenterpriseedition.com/documentation.html#_garbage_collector_performance_tuning).
- **Stream the sourced file on the server and the client** (this way only a small buffer is used, and the total size of the file is never allocated). This one is hard.


Note that the same issues apply to the master too (especially for the file serving part). But it's usually easier to run a different ruby interpreter (like REE) on the master than on all your clients.

Streaming HTTP requests is promising but unfortunately would require large change to how Puppet deals with HTTP. Maybe it can be done only for file content requests... This is something I'll definitely explore.

This file serving thing let me think about the following which I already discussed several time with Peter...

## File serving offloading

One of the mission of the _puppetmaster_ is to serve sourced file to its clients. We saw in the previous section that to do that the master has to read the file in memory. That's [one reason it is recommended](http://reductivelabs.com/trac/puppet/wiki/PuppetScalability.) to use a dedicated puppetmaster server to act as a **pure fileserver**.

But **there's a better way**, provided you run puppet behind [nginx](http://nginx.org/en/) or [apache](http://httpd.apache.org/). Those two proxies are also static file servers: why not leverage what they do best to serve the sourced files and thus offload our puppetmaster?

This has some advantages:

- it frees lots of resources on the puppetmaster, so that they can serve more catalogs by unit time
- the job will be done faster and by using less resources. Those static servers have been created to spoon-feed our puppet clients...


In fact it was impossible in 0.24.x, but now that file content serving is [RESTful](http://en.wikipedia.org/wiki/Representational_State_Transfer) it becomes trivial.

Of course offloading would give its best if your clients requires lots of sourced files that change often, or if you provision lots of new hosts at the same time because we're offloading only content, not file metadata. File content is served only if the client hasn't the file or the file checksum on the client is different.

### An example is better than thousand words

Imagine we have a standard manifest layout with:

- some globally sourced files under /etc/puppet/files and
- some modules files under /etc/puppet/modules/<modulename>/files.


Here is what would be the _nginx configuration_ for such scheme:
``` bash

server {
    listen 8140;

    ssl                     on;
    ssl_session_timeout     5m;
    ssl_certificate         /var/lib/puppet/ssl/certs/master.pem;
    ssl_certificate_key     /var/lib/puppet/ssl/private_keys/master.pem;
    ssl_client_certificate  /var/lib/puppet/ssl/ca/ca_crt.pem;
    ssl_crl                 /var/lib/puppet/ssl/ca/ca_crl.pem;
    ssl_verify_client       optional;

    root                    /etc/puppet;

    # those locations are for the "production" environment
    # update according to your configuration

    # serve static file for the [files] mountpoint
    location /production/file_content/files/ {
        # it is advisable to have some access rules here
        allow   172.16.0.0/16;
        deny    all;

        # make sure we serve everything
        # as raw
        types { }
        default_type application/x-raw;

        alias /etc/puppet/files/;
    }

    # serve modules files sections
    location ~ /production/file_content/[^/]+/files/ {
        # it is advisable to have some access rules here
        allow   172.16.0.0/16;
        deny    all;

        # make sure we serve everything
        # as raw
        types { }
        default_type application/x-raw;

        root /etc/puppet/modules;
        # rewrite /production/file_content/module/files/file.txt
        # to /module/file.text
        rewrite ^/production/file_content/([^/]+)/files/(.+)$  $1/$2 break;
    }

    # ask the puppetmaster for everything else
    location / {
        proxy_pass          http://puppet-production;
        proxy_redirect      off;
        proxy_set_header    Host             $host;
        proxy_set_header    X-Real-IP        $remote_addr;
        proxy_set_header    X-Forwarded-For  $proxy_add_x_forwarded_for;
        proxy_set_header    X-Client-Verify  $ssl_client_verify;
        proxy_set_header    X-SSL-Subject    $ssl_client_s_dn;
        proxy_set_header    X-SSL-Issuer     $ssl_client_i_dn;
        proxy_buffer_size   16k;
        proxy_buffers       8 32k;
        proxy_busy_buffers_size    64k;
        proxy_temp_file_write_size 64k;
        proxy_read_timeout  65;
    }
}

```

**EDIT:** the above configuration was missing the only content-type that nginx can return for Puppet to be able to actually receive the file content (that is raw).

I leave as an exercise to the reader the apache configuration.

It would also be possible to write some ruby/sh/whatever to generate the nginx configuration from the puppet fileserver.conf file.

And that's all folks, stay tuned for more Puppet (or even different) content.
