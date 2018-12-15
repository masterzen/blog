--- 

title: Nginx secure link module with TTL
date: 2009-07-18 18:57:22 +02:00
comments: true
wordpress_id: 63
wordpress_url: http://www.masterzen.fr/?p=63
category: 
- Programming
- PHP
- System Administration
- Nginx
tags: 
- PHP
- Nginx
- secure link
---
It's been a long time since my last post... which just means I was really busy both privately, on the Puppet side and at work (I'll talk about the Puppet side soon, for the private life you're on the wrong blog :-)).

For a project I'm working on at [Days of Wonder](http://www.daysofwonder.com), I had to use the [nginx secure link module](http://wiki.nginx.org/NginxHttpSecureLinkModule). This module allows a client to access to the pointed resource only if the given [MD5 HashMAC](http://en.wikipedia.org/wiki/Keyed-hash_message_authentication_code) matches the arguments.
## Nginx current secure link module

To use it, it's as simple as:

1. have your protected resources in /var/www/protected
2. have your back-end generate the correct url (see below)
3. use the following nginx config

``` bash

location /protected/ {
secure_link "this is my secret";
root /var/www/downloads;

if ($secure_link = "") {
return 403;
}

rewrite ^ /$secure_link break;
}
```

To generate an URL, use the following PHP snippet:

``` php
<?php $prefix = "http://www.domain.com/protected";

$protected_resource = "my-super-secret-resource.jpg";

$secret = "this is my secret";

$hashmac = md5( $protected_resource . $secret );

$url = $prefix . "/" . $hashmac . "/" . $protected_resource;

?>
```

## I want my protected URL to expire

But that wasn't enough for our usage. We needed the url to expire automatically after some time. So I crafted a small patch against Nginx 0.7.59.

## How does it work?

It just extends the nginx secure link module with a TTL. The time at which the resource expires is embedded in the url, and the HMAC. If the server finds that the current time is greater than the embedded time, then it denies access to the resource.

The timeout can't be tampered as it is used in the HMAC.

## Usage

The usage is the same as the current nginx secure link module, except:

1. you need to embed the timeout into the URL
2. you need to tell nginx about the TTL.


### On the back-end site

You need to use the following (sorry only PHP) code:

``` php

define(URL_TIMEOUT, 3600) # one hour timeout
$prefix = "http://www.domain.com/protected";
$protected_resource = "my-super-secret-resource.jpg";
$secret = "this is my secret";
$time = pack('N', time() + URL_TIMEOUT);
$timeout = bin2hex($time);

$hashmac = md5( $protected_resource . $time . $secret );

$url = $prefix . "/" . $hashmac . $timeout . "/" . $protected_resource;

```

### On Nginx side

``` bash

location /protected/ {
secure_link "this is my secret";
secure_link_ttl on;
root /var/www/protected;

if ($secure_link = "") {
return 403;
}

rewrite ^ /$secure_link break;
}
```

## Caveat

The server generating the url and hashmac and the one delivering the protected resource must have synchronized clocks.

There is no support. If it eats your server, then I or Days of Wonder can't be

## I want it!

It's simple:

1. [download the nginx secure link ttl patch](http://www.masterzen.fr/patches/nginx/nginx-secure-link-ttl.patch "The patch")
2. apply it to nginx-0.7.59 source tree (patch -p0 &lt; nginx-secure-link-ttl.patch)
3. configure nginx with --with-http_secure_link_module
4. **use and abuse**

