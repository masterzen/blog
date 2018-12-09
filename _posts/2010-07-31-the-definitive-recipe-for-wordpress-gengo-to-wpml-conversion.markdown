--- 

title: The definitive recipe for Wordpress Gengo to WPML conversion
date: 2010-07-31 16:48:27 +02:00
comments: true
wordpress_id: 204
wordpress_url: http://www.masterzen.fr/?p=204
categories: 
- System Administration
- War stories
- SQL
- Wordpress
tags: 
- sql
- gengo
- Wordpress
- wpml
- conversion
---
The [Days of Wonder News Center](http://blog.daysofwonder.com) is running [Wordpress](http://wordpress.org) which until a couple of days used [Gengo](http://wordpress.org/extend/plugins/gengo/) for multilingual stuff. Back when we started using _Wordpress_ for our news, we wanted to be able to have those in three (and maybe more) languages.

At that time (in 2007, wordpress 2.3), only _Gengo_ was available.
During the last years, _Gengo_ was unfortunately not maintained anymore, and it was difficult to upgrade Wordpress to new versions.

Recently we took the decision to upgrade our _Wordpress_ installation, and at the same time ditch _Gengo_ and start over using [WPML](http://wpml.org/), which is actively maintained (and looks superior to Gengo).

So, I started thinking about the conversion, then looked on the web and  found how to convert posts, with the help of those two blog posts:

- [Migrating Wordpress from Gengo to WPML](http://www.bernawebdesign.ch/byteblog/2009/08/15/migrating-wordpress-from-gengo-to-wpml/)
- [Converting Wordpress from Gengo to WPML - part 1](http://www.pietvanoostrum.com/en/wordpress/converting-wordpress-from-gengo-to-wpml/)


Those two posts were invaluable for the conversion of posts, but unfortunately nobody solved the conversion of translated categories... until I did :)

So here is the most complete recipe to convert from Gengo 2.5 to WPML 1.8, with updated and working SQL requests.

## Pre-requisites

You might want to stop the traffic to your blog during all this procedure. One way to do that is to return an HTTP error code 503 by modifying your Apache/Nginx/Whatever configuration.

1. Log-in as an administrator in the Wordpress back-end, and deactivate Gengo.
2. Install WPML 1.8, and activates it to create the necessary tables. I had to massage WPML a little bit to let it create the tables, YMMV.
3. In the WPML settings, define the same languages as in Gengo (in my case English (primary), French and German)
4. Finish the WPML configuration.
5. If you had a define(WP_LANG,...) in your wordpress config, get _rid of it_.

## Converting Posts

Connect to your MySQL server and issue the following revised SQL requests (thanks for the above blog posts for them):

{% gist 502282 Convert+Posts+from+Gengo+to+WPML.sql %}

## Converting Pages


This is the same procedure, except we track 'post_page' instead of 'post_post':

{% gist 502282 Convert+Pages+from+Gengo+to+WPML.sql %}

## Category conversion

This part is a little bit tricky. In Gengo, we translated the categories without creating new categories, but in WPML we have to create new categories that would be translations of a primary category.
To do this, I created the following SQL procedure that simplifies the creation of a translated category:

{% gist 502282 SQL+Procedure+to+create+a+translated+category.sql %}

Then we need to create translated categories with this procedure (this can be done with the Wordpress admin interface, but if you have many categories it is simpler to do this with a bunch of SQL statements):  

{% gist 502282 Convert+some+categories.sql %}

## Bind translated categories to translated posts

And this is the last step, we need to make sure our posts translations have the correct translated categories (for the moment they use the English primary categories).

To do this, I created the following SQL request:

{% gist 502282 Bind+French+posts+translations+to+French+categories.sql %}

The request is in two parts. The first one will list all the French translations posts IDs that we will report in the second request to update the categories links.

