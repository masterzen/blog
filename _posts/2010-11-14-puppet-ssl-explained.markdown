--- 

title: Puppet SSL explained
date: 2010-11-14 17:57:14 +01:00
comments: true
wordpress_id: 221
wordpress_url: http://www.masterzen.fr/?p=221
categories: 
- Puppet
- crypto
- ssl
tags: 
- puppet
- ssl
- crypto
- pki
- x509
---
The [puppet-users](http://groups.google.com/group/puppet-users) or [#puppet freenode irc channel](http://projects.puppetlabs.com/projects/puppet/wiki/IRC_Channel) is full of questions or people struggling about the [puppet SSL PKI](http://projects.puppetlabs.com/projects/puppet/wiki/Certificates_And_Security). To my despair, there are also people wanting to completely get rid of any security.

While I don't advocate the _live happy, live without security_ motto of some puppet users (and I really think a corporate firewall is only one layer of defense among many, not the ultimate one), I hope this blog post will help them shoot themselves in their foot :)

I really think SSL or the X509 PKI is simple once you grasped its underlying concept. If you want to know more about SSL, I really think everybody should read Eric Rescola's excellent "[SSL and TLS: Designing and Building Secure Systems](http://www.amazon.com/dp/0201615983)".

I myself had to deal with SSL internals and X509 PKI while I implemented a java secured network protocol in a previous life, including a cryptographic library.

## Purpose of Puppet SSL PKI

The current puppet security layer has 3 aims:

1. authenticate any node to the master (so that no rogue node can get a catalog from your master)
2. authenticate the master on any node (so that your nodes are not tricked into getting a catalog from a rogue master).
3. prevent communication eavesdropping between master and nodes (so that no rogue users can grab configuration secrets by listening to your traffic, which is useful in the cloud)


## A notion of PKI

PKI means: [Public Key Infrastructure](http://en.wikipedia.org/wiki/Public_key_infrastructure). But whats this?

A PKI is a framework of computer security that allows authentication of individual components based on public key cryptography. The most known system is the [x509](http://en.wikipedia.org/wiki/X.509) one which is used to protect our current web.

A public key cryptographic system works like this:

- every components of the system has a secret key (known as the _private key_) and a _public key_ (this one can be shared with other participant of the system). The public and private keys are usually bound by a cryptographic algorithm.
- authentication of any component is done with a simple process: a component signs a message with its own private key. The receiver can authenticate the message (ie know the message comes from the original component) by validating the signature. To do this, only the public key is needed.


There are different public/private key pair cryptosystem, the most known ones are RSA, DSA or those based on Elliptic Curve cryptography.

Usually it is not good that all participants of the system must know each other to communicate. So most of the current PKI system use a hierarchical validation system, where all the participant in the system must only know one of the parent in the hierarchy to be able to validate each others.

## X509 PKI

X509 is an ITU-T standard of a PKI. It is the base of the SSL protocol authentication that puppet use. This standard specifies certificates, certificate revocation list, authority and so on...

A given X509 certificate contains several information like those:

- Serial number (which is unique for a given CA)
- Issuer (who created this certificate, in puppet this is the CA)
- Subject (who this certificate represents, in puppet this is the node certname or fqdn)
- Validity (valid from, expiration date)
- Public key (and what kind of public key algorithm has been used)
- Various extensions (usually what this certificate can be used for,...)

You can check [RFC1422](http://www.ietf.org/rfc/rfc1422) for more details.

The certificate is usually the [DER encoding](http://en.wikipedia.org/wiki/Distinguished_Encoding_Rules) of the [ASN.1](http://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One) representation of those informations, and is usually stored as [PEM](http://en.wikipedia.org/wiki/Privacy_Enhanced_Mail) for consumption.

A given X509 certificate is signed by what we call a [Certificate Authority](http://en.wikipedia.org/wiki/Certificate_authority) (CA for short). A CA is an infrastructure that can sign new certificates. Anyone sharing the public key of the CA can validate that a given certificate has been validated by the CA.

Usually X509 certificate embeds a RSA public key with an exponent of 0x100001 (see below).  Along with a certificate, you need a private key (usually also PEM-encoded).

So basically the X509 system works with the following principle: CA are using their own private keys to sign components certificates, it is the CA role to sign only trusted component certificates. The trust is usually established out-of-bound of the signing request.

Then every component in the system knows the CA certificate (ie public key). If one component gets a message from another component, it checks the attached message signature with the CA certificate. If that validates, then the component is authenticated. Of course the component should also check the certificate validity, if the certificate has been revoked (from OCSP or a given CRL), and finally that the certificate subject matches who the component pretends to be (usually this is an hostname validation against some part of the certificate _Subject_)

## RSA system

Most of X509 certificate are based on the RSA cryptosystem, so let's see what it is.

The RSA cryptosystem is a public key pair system that works like this:

### Key Generation

To generate a RSA key, we chose two prime number _p_ and _q_.

We compute _n=pq_. We call _n_ the modulus.

We compute _φ_(_pq_) = (_p_ − 1)(_q_ − 1).

We chose e so that e&gt;1 and e&lt;_φ_(_pq_) (e and _φ_(_pq_) must be coprime). _e_ is called the exponent. It usually is 0x10001 because it greatly simplifies the computations later (and you know what I mean if you already implemented this :)).

Finally we compute _d=e^-1 mod((p-1)(q-1))_. This will be our secret key. Note that it is not possible to get d from only e (and since p and q are never kept after the computation this works).

In the end:

- _e_ and _n_ form the public key
- _d_ is our private key

### Encryption

So the usual actors when describing cryptosystems are Alice and Bob. Let's use them.

Alice wants to send a message _M_ to Bob. Alice knows Bob's public key _(e,n)_. She transform _M_ in a number &lt; _n _(this is called padding) that we'll call _m_, then she computes: _c = m^e . mod(n) _

### Decryption

When Bob wants to decrypt the message, he computes with his private key _d_: _m = c^d . mod(n)_

### Signing message

Now if Alice wants to sign a message to Bob. She first computes a hash of her message called _H_, then she computes: _s = H^(d mod n). _So she used her own private key. She sends both the message and the signature.

Bob, then gets the message computes _H _and computes _h' = H^(e mod n) _with Alice's public key. If _h' = h, _then only Alice could have sent it.

### Security

What makes this scheme work is the fundamental that finding p and q from n is a hard problem (understand for big values of n, it would take far longer than the validity of the message). This operation is called factorization. Current certificate are numbers containing  2048 bits, which roughly makes a 617 digits number to factor.

### Want to know more?

Then there are a couple of books really worth reading:

- [Applied Cryptography](http://amazon.com/dp/0471117099) - Bruce Schneier
- [Handbook of Applied Cryptography](http://amazon.com/dp/0849385237) - Alfred Menezes, Paul van Oorschot, Scott Vanstone


## How does this fit in SSL?

So SSL (which BTW means Secure Socket Layer) and now TLS (SSL successor) is a protocol that aims to provide security of communications between two peers. It is above the transport protocol (usually TCP/IP) in the OSI model. It does this by using [symmetric encryption](http://en.wikipedia.org/wiki/Symmetric-key_algorithm) and [message authentication code](http://en.wikipedia.org/wiki/Message_authentication_code) (MAC for short). The standard is (now) described in [RFC5246](http://tools.ietf.org/html/rfc5246).

It works by first performing an handshake between peers. Then all the remaining communications are encrypted and tamperproof.

This handshake contains several phases (some are optional):

1. Client and server finds the best encryption scheme and MAC from the common list supported by both the server and the clients (in fact the server choses).
2. The server then sends its certificate and any intermediate CA that the client might need
3. The server may ask for the client certificate. The client may send its certificate.
4. Both peers may validate those certificates (against a common CA, from the CRL, etc...)
5. They then generate the session keys. The client generates a random number, encrypts it with the server public key. Only the server can decrypt it. From this random number, both peers generate the symmetric key that will be used for encryption and decryption.
6. The client may send a signed message of the previous handshake message. This way the server can verify the client knows his private key (this is the client validation). This phase is optional.


After that, each message is encrypted with the generated session keys using a symmetric cipher, and validated with an agreed on MAC. Usual symmetric ciphers range from RC4 to AES. A symmetric cipher is used because those are usually way faster than any asymmetric systems.

## Application to Puppet

Puppet defines it's own Certificate Authority that is usually running on the master (it is possible to run a CA only server, for instance if you have more than one master).

This CA can be used to:

- generate new certificate for a given client out-of-bound
- sign a new node that just sent his Certificate Signing Request
- revoke any signed certificate
- display certificate fingerprints


What is important to understand is the following:

- Every node knows the CA certificate. _This allows to check the validity of the master from a node_
- _The master doesn't need the node certificate_, since it's sent by the client when connecting. It just need to make sure the client knows the private key and this certificate has been signed by the master CA.


It is also important to understand that when your master is running behind an Apache proxy (for Passenger setups) or Nginx proxy (ie some mongrel setups):

- The proxy is the SSL endpoint. It does all the validation and authentication of the node.
- Traffic between the proxy and the master happens in clear
- The master knows the client has been authenticated because the proxy adds an HTTP header that says so (usually _X-Client-Verify _for Apache/Passenger).


When running with webrick, webrick runs inside the puppetmaster process and does all this internally. Webrick tells the master internally if the node is authenticated or not.

When the master starts for the 1st time, it generates its own CA certificate and private key, initializes the CRL and generates a special certificate which I will call the _server certificate_. This certificate will be the one used in the SSL/TLS communication as the server certificate that is later sent to the client. This certificate subject will be the current master FQDN. If your master is also a client of itself (ie it runs a puppet agent), I recommend using this certificate as the client certificate.

The more important thing is that this server certificate advertises the following extension:

```
X509v3 Subject Alternative Name:
                DNS:puppet, DNS:$fqdn, DNS:puppet.$domain
```

What this means is that this certificate will validate if the connection endpoint using it has any name matching puppet, the current fqdn or puppet in the current domain.

By default a client tries to connect to the "_puppet_" host (this can be changed with --server which I don't recommend and is usually the source of most SSL trouble).

If your DNS system is well behaving, the client will connect to _puppet.$domain_. If your DNS contains a CNAME for puppet to your _real master fqdn_, then when the client will validate the server certificate it will succeed because it will compare "puppet" to one of those DNS: entries in the aforementioned certificate extension. BTW, if you need to change this list, you can use the --certdnsname option (note: this can be done afterward, but requires to re-generate the server certificate).

The whole client process is the following:

1. if the client runs for the 1st time, it generates a [Certificate Signing Request](http://en.wikipedia.org/wiki/Certificate_signing_request) and a private key. The former is an x509 certificate that is self-signed.
2. the client connects to the master (at this time the client is not authenticated) and sends its CSR, it will also receives the CA certificate and the CRL in return.
3. the master stores locally the CSR
4. the administrator checks the CSR and can eventually sign it (this process can be automated with autosigning). I strongly suggest verifying certificate fingerprint at this stage.
5. the client is then waiting for his signed certificate, which the master ultimately sends
6. All next communications will use this client certificate. Both the master and client will authenticate each others by virtue of sharing the same CA.


## Tips and Tricks


### Troubleshooting SSL

#### Certificate content

First you can check any certificate content with this:

{% gist 700124 puppet-ssl.sh %}

#### Simulate a SSL connection


You can know more information about a SSL error by simulating a client connection. Log in the trouble node and:

{% gist 700124 connect.sh %}

Check the last line of the report, it should say "Verify return code: 0 (ok)" if both the server and client authenticated each others. Check also the various information bits to see what certificate were sent. In case of error, you can learn about the failure by looking that the verification error message.

#### ssldump

Using [ssldump](http://www.rtfm.com/ssldump/) or [wireshark](http://www.wireshark.org/) you can also learn more about ssl issues. For this to work, it is usually needed to force the cipher to use a simple cipher like RC4 (and also ssldump needs to know the private keys if you want it to decrypt the application data).

#### Some known issues

Also, in case of SSL troubles make sure your master isn't using a different $ssldir than what you are thinking. If that happens, it's possible your master is using a different dir and has regenerated its CA. If that happens no one node can connect to it anymore. This can happen if you upgrade a master from gem when it was installed first with a package (or the reverse).

If you regenerate a host, but forgot to remove its cert from the CA (with puppetca --clean), the master will refuse to sign it. If for any reason you need to fully re-install a given node without changing its fqdn, either use the previous certificate or clean this node certificate (which will automatically revoke the certificate for your own security).

#### Looking to the CRL content:

{% gist 700124 crl.sh %}

Notice how the certificate serial number 3 has been revoked.


### Fingerprinting

Since puppet 2.6.0, it is possible to fingerprint certificates. If you manually sign your node, it is important to make sure you are signing the correct node and not a rogue system trying to pretend it is some genuine node.  To do this you can get the certificate fingerprint of a node by running puppet agent --fingerprint, and when listing on the master the various CSR, you can make sure both fingerprint match.

{% gist 700124 fingerprint.sh %}

### Dirty Trick

Earlier I was saying that when running with a reverse proxy in front of Puppet, this one is the SSL endpoint and it propagates the authentication status to Puppet.

**I strongly don't recommend implementing the following. This will compromise your setup security.**

This can be used to severely remove Puppet security for instance you can:

- make so that every nodes are authenticated for the server by always returning the correct header
- make so that nodes are authenticated based on their IP addresses or fqdn


You can even combine this with a mono-certificate deployment. The idea is that every node share the same certificate. This can be useful when you need to provision tons of short-lived nodes. Just generate on your master a certificate:


{% gist 700124 generate.sh %}

You can then use those generated certificate (which will end up in /var/lib/puppet/ssl/certs and /var/lib/puppet/private_keys) in a pre-canned $ssldir, provided you rename it to the local fqdn (or symlink it).  Since this certificate is already signed by the CA, it is valid. The only remaining issue is that the master will serve the catalog of this certificate certname. I proposed a patch to fix this, this patch will be part of 2.6.3. In this case the master will serve the catalog of the given connecting node and not the connecting certname.  Of course you need a relaxed auth.conf: 

{% gist 700124 relaxed-auth.conf %}

Caveat: I didn't try, but it should work. YMMV :)

**Of course if you follow this and shoot yourself in the foot, I can't be held responsible for any reasons, you are warned**. Think twice and maybe thrice before implementing this.

### Multiple CA or reusing an existing CA

This goes beyond the object of this blog post, and I must admit I never tried this. Please refer to: [Managing Multiple Certificate Authorities ](http://projects.puppetlabs.com/projects/puppet/wiki/Multiple_Certificate_Authorities) and  [Puppet Scalability](http://projects.puppetlabs.com/projects/puppet/wiki/Puppet_Scalability)

## Conclusion

If there is one: **security is necessary when dealing with configuration management**. We don't want any node to trust rogue masters, we don't want masters to distribute sensitive configuration data to rogue nodes. We even don't want a rogue user sharing the same network to read the configuration traffic. Now that you fully understand SSL, and the X509 PKI, I'm sure you'll be able to design some clever attacks against a Puppet setup :)

