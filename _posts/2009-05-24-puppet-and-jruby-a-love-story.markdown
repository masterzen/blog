--- 

title: Puppet and JRuby a love story!
date: 2009-05-24 22:55:54 +02:00
comments: true
wordpress_id: 52
wordpress_url: http://www.masterzen.fr/?p=52
categories: 
- Uncategorized
- Puppet
- System Administration
- Ruby
- Java
- Programming
tags: 
- ssl
- jruby
- puppet
- Ruby
- Java
- certificates
---
As announced in my last edit of my yesterday post [Puppet and JRuby a love and hate story](http://www.masterzen.fr/2009/05/23/puppet-and-jruby-a-love-and-hate-story/), I finally managed to run a [webrick](http://www.webrick.org) puppetmaster under [JRuby](http://www.jruby.org) with a MRI client connecting and fetching it's config.
## The Recipe

### Puppet side

Unfortunately Puppet creates its first certificate with a **serial number of 0**, which [JRuby-OpenSSL](http://github.com/jruby/jruby-openssl/tree/master) finds invalid (in fact that's [Bouncy Castle JCE Provider](http://www.bouncycastle.org/java.html)). So the first thing is to check if you already have some certificate generated with a serial of 0. If you have none, then everything is great you can skip this.

You can see a certificate content with openssl:

``` bash

% openssl x509 -text -in /path/to/my/puppet/ssl/ca/ca_cert.pem

Certificate:
Data:
Version: 3 (0x2)
Serial Number: 1 (0x1)
Signature Algorithm: sha1WithRSAEncryption
Issuer: CN=ca
Validity
Not Before: May 23 18:38:19 2009 GMT
Not After : May 22 18:38:19 2014 GMT
Subject: CN=ca
...

```

If no certificate has a serial of 0, then it's OK, otherwise I'm afraid you'll have to start the PKI from scratch (which means rm -rf $vardir/ssl and authenticate clients again), after applying the following Puppet patch:

``` ruby

JRuby fix: make sure certificate serial > 0

JRuby OpenSSL implementation is more strict than real ruby one and
requires certificate serial number to be strictly positive.

Signed-off-by: Brice Figureau <brice-puppet@daysofwonder.com>

diff --git a/lib/puppet/ssl/certificate_authority.rb b/lib/puppet/ssl/certificate_authority.rb
index 08feff0..4a7d461 100644
--- a/lib/puppet/ssl/certificate_authority.rb
+++ b/lib/puppet/ssl/certificate_authority.rb
@@ -184,7 +184,7 @@ class Puppet::SSL::CertificateAuthority
# it, but with a mode we can't actually read in some cases.  So, use
# a default before the lock.
unless FileTest.exist?(Puppet[:serial])
-            serial = 0x0
+            serial = 0x1
end

Puppet.settings.readwritelock(:serial) { |f|

```

I'll post this patch to [puppet-dev](http://groups.google.com/group/puppet-dev) soon, so I hope it'll eventually get merged soon in mainline.
### JRuby

You need the freshest JRuby available at this time. My test were conducted with latest JRuby as of commit "3aadd8a". The best is to clone the [github jruby repository](http://github.com/jruby/jruby/tree/master), and build it (it requires of course a JDK and Ant, but that's pretty much all).

Then install jruby in your path (if you need assistance for this, I'm not sure this blog post is for you :-))
### JRuby-OpenSSL

As I explained in my previous blog post about the same subject, Puppet exercises a lot the Ruby OpenSSL subsystem. During this experiment, I found a few shortcomings in the current JRuby-OpenSSL 0.5, including missing methods, or missing behaviors needed by Puppet to run fine.

So to get a fully Puppet enabled JRuby-OpenSSL you need either to get the very latest [JRuby-OpenSSL from its own github repository ](http://github.com/jruby/jruby-openssl/tree/master)(or checkout the [puppet-fixes branch of my fork of said repository on github](http://github.com/masterzen/jruby-openssl/tree/puppet-fixes)) and or apply manually the following patches on top of the 0.5 source tarballs:

- [JRUBY-3689](http://jira.codehaus.org/browse/JRUBY-3689): OpenSSL::X509::CRL can't be created with PEM content

- [JRUBY-3690](http://jira.codehaus.org/browse/JRUBY-3690): OpenSSL::X509::Request can't be created from PEM content

- [JRUBY-3691](http://jira.codehaus.org/browse/JRUBY-3691): Implement OpenSSL::X509::Request#to_pem

- [JRUBY-3692](http://jira.codehaus.org/browse/JRUBY-3692): Implement OpenSSL::X509::Store#add_file

- [JRUBY-3693](http://jira.codehaus.org/browse/JRUBY-3693): OpenSSL::X509::Certificate#check_private_key is not implemented

- [JRUBY-3556](http://jira.codehaus.org/browse/JRUBY-3556): Webrick doesn't start in https

- [JRUBY-3694](http://jira.codehaus.org/browse/JRUBY-3694): Webrick HTTPS produces some SSL stack trace


Then rebuild JRuby-OpenSSL which is a straightforward process (copy build.properties.SAMPLE to build.properties, adjust jruby.jar path, and then issue ant jar to build the jopenssl.jar).

Once done, install the 0.5 JRuby-OpenSSL gem in your jruby install, and copy other the built jar in lib/ruby/gems/1.8/gems/jruby-openssl-0.5/lib.
## Let's try it!

Then it's time to run your puppetmaster, just start it with _jruby_ instead of ruby. Of course you need the puppet dependencies installed (Facter).

My next try will be to run Puppet on Jruby and mongrel (or what replaces it in JRuby world), then try with storeconfig on...

Hope that helps, and for any question, please post in the [puppet-dev](http://groups.google.com/group/puppet-dev) list.
