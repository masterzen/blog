--- 

title: Benchmarking puppetmaster stacks
date: 2010-10-18 22:48:49 +02:00
comments: true
wordpress_id: 215
wordpress_url: http://www.masterzen.fr/?p=215
categories: 
- System Administration
- Puppet
tags: 
- puppet
- puppetmaster
- performance
- benchmark
- puppet-load
---
It's been a long time since my last [puppet blog post about file content offloading](http://www.masterzen.fr/2010/03/21/more-puppet-offloading/). Two [puppetcamps](http://www.puppetlabs.com/community/puppet-camp/puppet-camp-faq/) even passed (more on the last one in a next blog article). A [new major puppet release ](http://www.puppetlabs.com/misc/download-options/)(2.6) was even released, addressing lots of performance issues (including the file streaming patch I contributed).

In this new major version, I contributed a _new 3rd party executable _(available in the ext/ directory in the source tree) that allows to simulate concurrent nodes hammering a puppetmaster. This tool is called **puppet-load**.

## Rationale

I created this tool for several reasons:

- I wanted to be able to _benchmark and compare several ruby interpreter_ (like comparing JRuby against MRI)
- I wanted to be able to _benchmark and compare several deployements _solutions (like passenger against mongrel)


There was already a testing tool (called _puppet-test_) that could do that. Unfortunately puppet-test had the following issues:

- No REST support besides some never merged patches I contributed, which render it moot to test 0.25 or 2.6 :(
- based on a forking process models, so simulating many clients is not resource friendly
- it consumes the master response and fully unserializes it creating puppet internals objects, which takes plenty of RAM and time, penalizing the concurrency.
- no useful metrics, except the time the operation took (which was in my test mostly dominated by the unserialization of the response)

Based on those issues, I crafted from scratch a tool that:

- is able to impose an _high concurrency_ to a puppetmaster, because it is based on EventMachine (no threads or processes are harmed in this program)
- is _lightweight_ because it doesn't consume puppet responses
- is able to gather some (useful or not) _metrics_ and _aggregates_ them


## Caveats

For the moment, puppet-load is still very new and only supports catalog compilations for a single node (even though it simulates many clients in parallel requesting this catalog). I just released a patch to support multiple node catalogs. I also plan to support file sourcing in the future.

So far, since puppet-load exercise a puppetmaster in such a hard way, achieving concurrencies nobody has seen on production puppetmasters, we were able to find and fix half a dozen threading race condition bugs in the puppet code (some have been fixed in 2.6.1 and 2.6.2, the others will soon be fixed).

## Usage

The first thing to do is to generate a certificate and its accompanying private key:

{% gist 633063 GenerateCertificates.sh %}

Then modify your auth.conf (or create one if you don't have one) to allow puppet-load to compile catalos. Unfortunately until [#5020](http://projects.puppetlabs.com/issues/5020) is merged, the puppetmaster will use the client certname as the node to compile instead of the given URI. Let's pretend your master has the patch #5020 applied (this is a one-liner).  

{% gist 633063 auth.conf%20modification %}

Next, we need the facts of the client we'll simulate. Puppet-load will overwrite the 'fqdn', 'hostname' and 'domain' facts with values inferred from the current node name.

{% gist 633063 facts.yaml %}

Then launch puppet-load against a puppet master:

{% gist 633063 puppet-load-cli.sh %}

If we try with an higher concurrency (here my master is running under webrick with a 1 resource catalog, so compilations are extremely fast):

{% gist 633063 gistfile4.txt %}

It returns a bunch of informations. First if you ran it in debug mode, it would have printed when it would start simulated clients (up to the given concurrency) and when it receives the response.

Then it displays some important information:

- availability %: which is the percent of non-error response it received
- min and max request time
- average and median request time (this can be used to see if the master served clients in a fair way)
- real concurrency: how many clients the master was able to serve in parallel
- transaction rate: how many compilation per seconds the master was able to perform (I expect this number to vary in function of applied concurrency)
- various transfer metrics like throughput and catalog size transferred: this can be useful to understand the amount of information transferred to every clients (hint: puppet 2.6 and puppet-load both support http compression)


At last puppetcamp, Jason Wright from Google, briefly talked about puppet-load (thanks Jason!). It was apparently already helpful to diagnose performance issues in his External Node Tool classifier.

If you also use puppet-load, and/or have ideas on how to improve it, please let me know!
If you have interesting results to share like comparison of various puppet master stacks, let me know!

