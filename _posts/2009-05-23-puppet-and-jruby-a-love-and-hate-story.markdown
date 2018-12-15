--- 

title: Puppet and JRuby, a love and hate story
date: 2009-05-23 18:15:38 +02:00
comments: true
wordpress_id: 46
wordpress_url: http://www.masterzen.fr/?p=46
category: 
- Programming
- Puppet
- System Administration
- Ruby
- Java
tags: 
- ssl
- jruby
- puppetmaster
- puppet
- Java
- openssl
---
Since I heard about [JRuby](http://www.jruby.org) about a year ago, I wanted to try to run [my favorite ruby program](http://www.reductivelabs.com/puppet) on it. I'm working with Java almost all day long, so I know for sure that the Sun JVM is a precious tool for running long-lived server. It is _pretty fast_, and has a very good (and tunable) [garbage collector](http://en.wikipedia.org/wiki/Garbage_collection_(computer_science)).

In a word: the _perfect system_ to run a long-lived puppetmaster!

The first time I tried, back in February 2009, I unfortunately encountered the bug [JRUBY-3349](http://jira.codehaus.org/browse/JRUBY-3349 "Fcntl constants not available") which prevented Puppet to run quite early, because the Fcntl constants weren't defined. Since my understanding of JRuby internal is near zero, I left there.

But thanks to [Luke Kanies](http://madstop.com/) (Puppet creator), one of the JRuby main developers [Charles Oliver Nutter](http://blog.headius.com/) fixed the issue a couple of weeks ago (thanks to him, and they even fixed another issue at about the same time about fcntl which didn't support SET_FD).

That was just in time for another test...

But what I forgot was that Puppet is not every ruby app on the block. It uses lots of cryptography behind the scene. Remember that Puppet manages its own PKI, including:

- a full Certification Authority.
- a CRL.
- authenticated clients connections, through SSL.


That just means Puppet exercise a lot the Ruby OpenSSL extension.

The main issue is that [MRI](http://www.ruby-lang.org/en/) uses [OpenSSL](http://www.openssl.org/) for all the cryptographic stuff, and JRuby uses [a specific Java version of this extension](http://github.com/jruby/jruby-openssl/tree/master). Of course this later is still young (presently at v 0.5) and doesn't contain yet everything needed to be able to run Puppet.

In another life I wrote a proprietary cryptographic Java library, so I'm not a complete cryptography newcomer (OK, I forgot almost everything, but I still have some good books to refer to). So I decided to implement what is missing in JRuby-openssl to allow a webrick Puppetmaster to run.

You can find my contributions in the various [JRUBY-3689](http://jira.codehaus.org/browse/JRUBY-3689), [JRUBY-3690](http://jira.codehaus.org/browse/JRUBY-3690), [JRUBY-3691](http://jira.codehaus.org/browse/JRUBY-3691), [JRUBY-3692](http://jira.codehaus.org/browse/JRUBY-3692), [JRUBY-3693](http://jira.codehaus.org/browse/JRUBY-3693) bugs.

I still have another a minor patch to submit (OpenSSL::X509::Certificate#to_text implementation).

So the question is: with _all that patches_ applied, did I get a puppetmaster running?

And the answer is **unfortunately no**.

I can get the puppetmaster to start on a fresh configuration (ie it creates everything SSL related and such), but it fails as soon a client connects (hey that's way better than before I started :-)).

All comes _from SSL_. The issue is that  with the C OpenSSL implementation it is possible to get the peer certificate anytime, but the java SSL implementation (which is provided by the Sun virtual machine) requires the client to be authenticated before anyone get access to the peer certificate.

That's unfortunate because to be able to authenticate a not-yet-registered client, we must have access to its certificate. I couldn't find any easy code fix, so I stopped my investigations there.

There is still some possible workarounds, like running in mongrel mode (provided JRuby supports mongrel which I didn't check) and let [Nginx](http://nginx.net/) (or Apache) handle the SSL stuff, but still it would be great to be able to run a full-fledged puppetmaster on JRuby.

I tried with a known client and get the same issue, so maybe that's a whole different issue, I guess I'll have to dig deeper in the Java SSL code, which unfortunately is not available :-)

Stay tuned for more info about this. I hope to be able to have a full puppetmaster running on JRuby soon!

EDIT: I could run a full puppetmaster on webrick from scratch under JRuby with a normal ruby client. I'll post the recipe in a subsequent article soon.
