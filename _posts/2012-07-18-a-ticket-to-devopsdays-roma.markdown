---

title: "Ticket to Devopsdays Roma?"
date: 2012-07-19 20:18:12
comments: true
categories: 
 - devops
tags: 
 - devops
---

After seeing [@KrisBuytaert](http://twitter.com/krisbuytaert) tweet a couple of days ago about offering priority registration for the upcoming [Devopsdays Roma](http://www.devopsdays.org/events/2012-italy/) next October to people blogging about *Devops*, I thought why not me?

I already wanted to attend the last European [Devopsdays session in Goteborg](http://www.devopsdays.org/events/2011-goteborg/) last year, but time proximity with the [PuppetConf](http://puppetconf.com/) and some work schedule prevented me to finally join the party.

This year, I won't show up in San Francisco the yearly Puppet big event (which at least from there sounds quite terrific) for various reasons, so if attending a Devopsdays conference had a certain appeal I really couldn't resist (and choosing one in Europe, well is much more easier for me).

## Qualifying

I believe (feel free to speak up if you think not) I can qualify for being part of the devops movement (and per se can attend Devopsdays Roma) :)

One reason is that my work job is mostly programming. But I also have the fine responsibility of bringing what I write to production systems, along with creating and managing the infrastructure.

This puts me in a situation that not a lot of my fellow programmers experienced. From a long time, producing software for Software Engineers was compiling a binary artifact and handle it into other hands, then work as soon as possible on new software.

Unfortunately in the real world, this doesn't really work. The ops people in charge of the application (and that would be the same for client side products with respect to support engineers) will struggle to deploy, analyze and simply maintain it.

When you already experienced both side of the world, you know that what matters to a Software Engineers (ie clean code, re-usable components, TDD and unit testing...) doesn't really matters to Operations Engineers.
The latter currently wants:

* logs
* ease of administration (like changing configuration gracefully)
* ease of introspection (like usable logs, integrated consoles, useful metrics, trace mechanism ala Dapper)
* ease of deployment (like packaging system, artifacts assembly that contains comprehensible dependencies)
* external (and internal) monitoring of all aspects
* wisely chosen hard dependencies (like database, message queues or cache systems)

Well, if you're a developer you'll recognize like me that the above list is really not trivial to bring, and usually tends to be overcome.

Unfortunately, an application that doesn't implement this will be hard or impossible to properly maintain.

The first time I tried to deploy software I wrote, I discovered the hard way that those requirements are, well, requirements.
Now, I make sure that the projects I work on have user stories encompassing those essential facets.

## Ops already know it

If you're on the operation side, then you already know the value of those software requirements. Our role as operation engineers is to evangelize and teach software engineers those good practices. I strongly believe that *devops* is all about that. 

But it's not only this. It's also being agile on the infrastructure side...

## Puppet opened my eyes

I always had been interested in managing server infrastructures. I started managing linux servers about 12 years ago (about 5 years after professionally starting as a software developer). Managing servers has always been something on the side for me, my main job being producing software (either client or server side).

I was lurking the configuration management space and community for a long time before I adopted Puppet. On the small infrastructure I was maintaining, I thought it would be overkill. 

Oh, how I was wrong at that time :)

Back in 2007, I started using Puppet, and began to write modules for the software we were using in production. I was still too shy to run this in production. Then in 2008, I really started using puppet (and BTW, contributing some features I thought interesting, which you already know if you read this infrequently updated blog).

Puppet helped me to:

* have all my configuration centralized in git
* deploy servers with repeatable process (ie recreate servers from scratch)
* parallelize (clusters can be spawned much more easily)
* prevent configuration drift
* orchestrate multiple nodes configurations (ie publish monitoring or backup information to other nodes)

Puppet helped me understand that tools are a real life savers.

I also learnt (and actually enforced) good administration practice:

* deploy native packages instead of source installs
* setup monitoring for every installed critical software
* no manual configuration on servers anymore
* configuration testing on VM (thanks Vagrant BTW)
* automate as much as you can

Puppet also helped me join sysadmin communities (like the find folks at ##infra-talk), which in turn helped me discover other life saver tools.

This, I think, is part of the *devops* culture and community.

## It's not reserved to server-side

Yes, it isn't. Support staff or customer service staff share the same responsibilities as the operation teams but for client side applications. There is now much more client software than ever with the number of smartphones out there.

The same benefit of *devops* I talked about earlier, can and should also be applied to client side software. Logs are invaluable when trying to understand why some software your dev team wrote doesn't work when in the hand of your clients. 

It's even much more complex than analyzing server-side issues, because when you have the chance of managing client applications that produce logs, it's most of the time impossible to get access to them...

## Is devops the future?

My own small goal (my stone to the devops edifice) is to start the cultural mindset shift of the more developers I can (starting with my fellow co-workers). And I think that's our own responsibility as part of the *devops* movement (if we can use this word) to initiate such shift.

I always smile when I see "devops engineer" job positions. Devops is not a role, it's a mindset that everybody in a given dev and ops team should share. Maybe recruiters use this word as a synonym for "help us use automation tools", as if it was the only solution to a human problem (well obviously if you don't use any configuration management you have more problems to solve)

The same way olympic athletes practice hard every day to reach their level, I strongly believe that those *devops* practice I described should be adopted by all software developers.

Now it's our job to spread the word and help engineers to.

Finally, in my humble opinion, *devops* is all about common sense. I think it's easier to implement such practices in small companies/teams than in larger already installed teams (people are usually reluctant to changes, being good or bad). Nevertheless, if developers and operations unite and walk in the same direction, big things can be achieved.

## What happens at Devopsdays...

... should not stay at Devopsdays (well except maybe for the drinks outcome)

What do I want to get from attending Devopsdays Roma?

I really want to:

* learn new things
* learn about other people experiences in the field
* share about fixing problems that plagues us all like:
 * monitoring sucks
 * log processing/centralization (and developer access)
* network and learn from wise and knowledgeable peers

And now I wish I'll be there and that I'll meet you :)
