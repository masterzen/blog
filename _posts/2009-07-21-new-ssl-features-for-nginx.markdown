--- 

title: New SSL features for Nginx
date: 2009-07-21 18:54:16 +02:00
comments: true
wordpress_id: 74
wordpress_url: http://www.masterzen.fr/?p=74
category: 
- Programming
- System Administration
- Puppet
- Nginx
tags: 
- ssl
- Nginx
- patch
- crl
---
As a [Puppet Mongrel Nginx](http://reductivelabs.com/trac/puppet/wiki/UsingMongrelNginx) user, I'm really ashamed about the convoluted nginx configuration needed (two server blocks listening on different ports, you need to direct your clients CA interactions to the second port with --ca_port), and the lack of support of proper CRL verification.

If you are like me, then there is some hope in this blog post.

Last week-end, I did some intense Puppet hacking (certainly more news about this soon), and part of this work is two Nginx patch:

- The first one adds support for ssl_client_verify optional. In this mode nginx accepts a client without a certificate, and of course accepts a client as long as it verifies against the CA certificate.
- The second patch adds support for CRL PEM files (the one we usually deploy in Puppet).


## Installation

First, download both patches:

- [Support ssl_client_verify optional and $ssl_client_verify](http://www.masterzen.fr/patches/nginx/0001-Support-ssl_client_verify-optional-and-ssl_client_v.patch)
- [Add SSL CRL verifications](http://www.masterzen.fr/patches/nginx/0002-Add-SSL-CRL-verifications.patch)


Then apply them to Nginx (tested on 0.7.59):
``` sh

$ cd nginx-0.7.59
$ patch -p1 < ../0001-Support-ssl_client_verify-optional-and-ssl_client_v.patch
$ patch -p1 < ../0002-Add-SSL-CRL-verifications.patch

```

Then build Nginx as usual.

## Usage

Here is a revised Puppet Nginx Mongrel configuration:
``` sh

upstream puppet-production {
  server 127.0.0.1:18140; 
  server 127.0.0.1:18141;
}

server {
  listen 8140;

  ssl                     on;
  ssl_session_timeout     5m;
  ssl_certificate         /var/lib/puppet/ssl/certs/puppetmaster.pem;
  ssl_certificate_key     /var/lib/puppet/ssl/private_keys/puppetmaster.pem;
  ssl_client_certificate  /var/lib/puppet/ssl/ca/ca_crt.pem;
  ssl_ciphers             SSLv2:-LOW:-EXPORT:RC4+RSA;
  # allow authenticated and client without certs
  ssl_verify_client       optional;
  # obey to the Puppet CRL
  ssl_crl /var/lib/puppet/ssl/ca/ca_crl.pem;
  
  root                    /var/tmp;

  location / {
    proxy_pass              http://puppet-production;
    proxy_redirect         off;
    proxy_set_header    Host             $host;
    proxy_set_header    X-Real-IP        $remote_addr;
    proxy_set_header    X-Forwarded-For  $proxy_add_x_forwarded_for;
    proxy_set_header    X-Client-Verify  $ssl_client_verify;
    proxy_set_header    X-SSL-Subject    $ssl_client_s_dn;
    proxy_set_header    X-SSL-Issuer     $ssl_client_i_dn;
    proxy_read_timeout  65;
  }
}

```

Reload nginx, and enjoy :-)
