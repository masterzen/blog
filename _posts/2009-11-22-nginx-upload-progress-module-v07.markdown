--- 

title: Nginx upload progress module v0.7!
date: 2009-11-22 12:24:50 +01:00
comments: true
wordpress_id: 138
wordpress_url: http://www.masterzen.fr/?p=138
category: 
- Programming
- System Administration
- Nginx
- C
tags: 
- Nginx
- nginx upload progress
- nginx module
- release
---
I'm proud to announce the release of [Nginx Upload Progress](http://github.com/masterzen/nginx-upload-progress-module) module v0.7

This version sees a crash fix and various new features implemented by Valery Kholodkov (the author of the famous [Nginx Upload Module](http://www.grid.net.ru/nginx/upload.en.html)).

This version has been tested with Nginx 0.7.64.

## Changes


- fixed segfault when uploads are aborted (thanks to Markus  Doppelbauer for his bug report)
- session ID header name is now configurable (thanks to Valery Kholodkov)
- Added directive to format output as pure json (thanks to Valery  Kholodkov)
- Added directive to format output with configurable template (thanks  to Valery Kholodkov)
- Added directive to set a probe response content-type (thanks to  Valery Kholodkov)
- Added upload status variables (needs a status patch) (thanks to  Valery Kholodkov)


## What's now cool!

What is cool is that now with only one directive (upload_progress_json_output) the responses are sent in pure Json and not in javascript mix as it was before.

Another cool feature is the possibility to use templates to send progress information. That means with a simple configuration change nginx can now return XML:

``` bash
upload_progress_content_type 'text/xml';
upload_progress_template starting '<upload><state>starting</state></upload>';
upload_progress_template uploading '<upload><state>uploading</state><size>$uploadprogress_length</size><uploaded>$uploadprogress_received</uploaded></upload>';
upload_progress_template done '<upload><state>done</state></upload>';
upload_progress_template error '<upload><state>error</state></upload>``$uploadprogress_status``';
```

Refer to the README in the distribution for more information.

## How do you get it?

Easy, download the tarball from the [nginx upload progress module github repository download section](http://github.com/masterzen/nginx-upload-progress-module/downloads).

## How can I use it?

Normally you have to use your own client code to display the progress bar and contact nginx to get the progress information.

But some nice people have created various javascript libraries doing this for you:

- [JQuery upload progress module](http://github.com/drogus/jquery-upload-progress)
- [Protoype upload progress module](http://github.com/edgarjs/prototype-nginx-upload-progress)


Happy uploads!
