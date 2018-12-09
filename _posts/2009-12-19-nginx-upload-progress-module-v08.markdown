--- 

title: Nginx upload progress module v0.8!
date: 2009-12-19 20:46:42 +01:00
comments: true
wordpress_id: 145
wordpress_url: http://www.masterzen.fr/?p=145
categories: 
- Programming
- System Administration
- Nginx
- C
tags: 
- Nginx
- nginx upload progress
- nginx module
---
Yes, I know... I [released v0.7 less than a month ago](http://www.masterzen.fr/2009/11/22/nginx-upload-progress-module-v07/). But this release was [crippled by a crash](http://github.com/masterzen/nginx-upload-progress-module/issues/closed/#issue/2) that could happen at start or reload.

## Changes

Bonus in this new version, brought to you by [Tizoc](http://github.com/tizoc):

- JSONP support
- Long awaited fix for X-Progress-ID to be the last parameter in the request parameter

If you wonder what JSONP is (as I did when I got the merge request), you can check [the original blog post that lead to it](http://bob.pythonmac.org/archives/2005/12/05/remote-json-jsonp/).

To activate JSONP you need:

1. to use the upload_progress_jsonp_output in the progress probe location
2. declare the JSONP parameter with the upload_progress_jsonp_parameter


This version has been tested with 0.7.64 and 0.8.30.

## How do you get it?

Easy, download the tarball from the [nginx upload progress module github repository download section](http://github.com/masterzen/nginx-upload-progress-module/downloads).

If you want to report a bug, please use the [Github issue section](http://github.com/masterzen/nginx-upload-progress-module/issues).

