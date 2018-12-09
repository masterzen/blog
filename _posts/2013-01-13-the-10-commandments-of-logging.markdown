---

title: "The 10 commandments of logging"
date: 2013-01-13 15:55:26
comments: true
categories: 
 - devops
tags: 
 - devops
---

Welcome on my blog for this new Year. After writing an answer to a thread regarding monitoring and log monitoring on the Paris devops mailing list, I thought back about a blog post project I had in mind for a long time.

I wrote this blog post while wearing my Ops hat and this is mostly addressed to developers.

Knowing how and what to log is, to me, one of the hardest task a software engineer will have to solve. Mostly because this task is akin to divination. It's very hard to know what information you'll need during troubleshooting... That's the reason I hope those 10 commandments will help you enhance your application logging for the great benefits of the ops engineers :)

## 1. Thou shalt not write log by yourself

Never, ever use printf or write your log entries by yourself to files, or handle log rotation by yourself. Please do your ops guys a favor and use a standard library or system API call for this.

This way, you're sure the running application will play nicely with the other system components, will log to the right place or network services without special system configuration.

So, if you just use the system API, then this means logging with ``syslog(3)``. Learn how to use it.

If you instead prefer to use a logging library, there are plenty of those especially in the Java world, like [Log4j](http://logging.apache.org/log4j/2.x/), [JCL](https://commons.apache.org/logging/guide.html), [slf4j](http://www.slf4j.org/) and [logback](http://logback.qos.ch/). My favorite is the combination of slf4j and logback because it is very powerful and relatively easy to configure (and allows JMX configuration or reloading of the configuration file).

The best thing about slf4j is that you can change the logging backend when you see fit. It is especially important if you're coding a library, because it allows anyone to use your library with their own logging backend without any modification to your library.

There are also several other logging library for different languages, like for ruby: [Log4r](http://log4r.rubyforge.org/), [stdlib logger](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger/Application.html), or the almost perfect [Jordan Sissel's Ruby-cabin](https://github.com/jordansissel/ruby-cabin)

And if your argument for not using a logging library is CPU consumption, then you have my permission to skip this blog post. Sure you should not put log statements in tight inner loops, but otherwise you'll never see the difference.

## 2. Thou shalt log at the proper level

If you followed the 1st commandment, then you can use a different log level per log statement in your application. One of the most difficult task is to find at what level this log entry should be logged. 

I'm giving here some advice:

* _TRACE level_: this is [a code smell](http://www.lenholgate.com/blog/2005/07/no-thats-not-the-point-and-yes-trace-logging-is-bad.html) if used in production. This should be used during development to track bugs, but never committed to your VCS.

* _DEBUG level_: log at this level about anything that happens in the program. This is mostly used during debugging, and I'd advocate trimming down the number of debug statement before entering the production stage, so that only the most meaningful entries are left, and can be activated during troubleshooting.

* _INFO level_: log at this level all actions that are user-driven, or system specific (ie regularly scheduled operations...)

* _NOTICE level_: this will certainly be the level at which the program will run when in production. Log at this level all the notable event that are not considered an error.

* _WARN level_: log at this level all event that could potentially become an error. For instance if one database call took more than a predefined time, or if a in memory cache is near capacity. This will allow proper automated alerting, and during troubleshooting will allow to better understand how the system was behaving before the failure.

* _ERROR level_: log every error conditions at this level. That can be API calls that return errors or internal error conditions.

* _FATAL level_: too bad it's doomsday. Use this very scarcely, this shouldn't happen a lot in a real program. Usually logging at this level signifies the end of the program. For instance, if a network daemon can't bind a network socket, log at this level and exit is the only sensible thing to do.

Note that the default running level in your program or service might widely vary. For instance I run my server code at level _INFO_ usually, but my desktop programs runs at level _DEBUG_. Because it's very hard to troubleshoot an issue on a computer you don't have access too, and it's far easier when doing support or customer service to ask the user to send you the log than teaching her to change the log level and then send you the log. Of course YMMV :)

## 3. Honor thy log category

Most logging library I cited in the 1st commandment allow to specify a logging category. This category allows to classify the log message, and will ultimately, based on the logging framework configuration, be logged in a distinct way or not logged at all.

Most of the time java developers use the fully qualified class name where the log statement appears as the category. This is a scheme that works relatively fine if your program respects the [simple responsibility principle](https://en.wikipedia.org/wiki/Single_responsibility_principle).

Log categories in java logging libraries are hierarchical, so for instance logging with category ``com.daysofwonder.ranking.ELORankingComputation`` would match the top level category ``com.daysofwonder.ranking``. This would allow the ops engineer to setup a logging configuration that works for all the ranking subsystem by just specifying configuration for this category. But it could at the same time, produce logging configuration for child categories if needed.

We can extend the paradigm a little bit further to help troubleshooting specific situation. Imagine that you are dealing with a server software that respond to user based request (like a REST API for instance). If your server is logging with this category ``my.service.api.<apitoken>`` (where apitoken is specific to a given user), then you could either log all the api logs by allowing ``my.service.api`` or a single misbehaving api user by logging with a more detailed level and the category ``my.service.api.<bad-user-api-token>``.
Of course this requires a system where you can change logging configuration on the fly.

## 4. Thou shalt write meaningful logs

This might probably be the most important commandment. There's nothing worst than cryptic log entries assuming you have a deep understanding of the program internals.

When writing your log entries messages, always anticipate that there are emergency situations where the only thing you have is the log file, from which you have to understand what happened. Doing it right might be the subtle difference between getting fired and promoted :)

When a developer writes a log message, it is in the context of the code in which the log directive is to be inserted. In those conditions we tend to write messages the infer on the current context. Unfortunately when reading the log itself this context is absent, and those messages might not be understandable.

One way to overcome this situation (and that's particularly important when writing at the warn or error level), is to add remediation information to the log message, or if not possible, what was the purpose of the operation, and it's outcome.

Also, do not log message that depends on previous messages content. The reason is that those previous messages might not appear if they are logged in a different category or level, or worst can appear in a different place (or way before) in a multi-threaded or asynchronous context.

## 5. Thy log shalt be written in English

This might seem a strange commandment, especially coming from a French guy. First, I still think English is much more concise than French and better suits technical language. Why would you want to log in French if the message contains more than 50% of English words in it?

This being put aside, here are the essential reason behind this commandment:

* English means your messages will be in logged with ASCII characters. This is particularly important because you can't really know what will happen to the log message, nor what software layer or media it will cross before being archived somewhere. If your message uses a special charset or even UTF-8, it might not render correctly at the end, but worst it could be corrupted in transit and become unreadable. Still remains the question of logging user-input which might be in diverse charset and/or encoding.

* If your program is to be used by the most and you don't have the resources for a full localization, then English is probably your best alternative. Now, if you have to localize one thing, localize the interface that is closer to the end-user (it's usually not the log entries).

* if you localize your log entries (like for instance all the warning and error level), make sure you prefix those by a specific meaningful error-code. This way people can do language independent Internet search and find information. Such great scheme has been used a while ago in the VMS operating system, and I must admit it is very effective. If you were to design such scheme, you can adopt this scheme: APP-S-CODE or APP-S-SUB-CODE, with respectively:
  * APP: your application name on 3 letters
  * S: severity on 1 letter (ie D: debug, I: info...)
  * SUB: the sub part of the application this code pertains to
  * CODE: a numeric code specific to the error in question

## 6. Thou shalt log with context

So, there's nothing worst than this kind of log message:

```
 Transaction failed
```

or

```
User operation succeeds
```

or in case of API exceptions:

```
java.lang.IndexOutOfBoundsException
```  

Without proper context, those messages are only noise, they don't add value and consume space that could have been useful during troubleshooting.

Messages are much more valuable with added context, like:

```
Transaction 2346432 failed: cc number checksum incorrect
```

or

```
User 54543 successfully registered e-mail user@domain.com
```
or

```
IndexOutOfBoundsException: index 12 is greater than collection size 10
```

Since we're talking about exceptions in this last context example, if you happen to propagate up exceptions, make sure to enhance them with context appropriate to the current level, to ease troubleshooting, as in this java example:

```java
  public void storeUserRank(int userId, int rank, String game) {
    try {
      ... deal database ...
    } catch(DatabaseException de) {
      throw new RankingException("Can't store ranking for user "+userId+" in game "+ game + " because " + de.getMessage() );
    }
  }
```

So the upper-layer client of the rank API will be able to log the error with enough context information. It's even better if the context becomes parameters of the exception itself instead of the message, this way the upper layer can use remediation if needed.

An easy way to keep a context is to use the [_MDC_](http://www.slf4j.org/manual.html#mdc) some of the java logging library implements. The _MDC_ is a per thread associative array. The logger configuration can be modified to always print the _MDC_ content for every log line. If your program uses a per-thread paradigm, this can help solve the issue of keeping the context. For instance this java example is using the _MDC_ to log per user information for a given request:

```java
  class UserRequest {
    ...
    public void execute(int userid) {
      MDC.put("user", userid);
      
      // ... all logged message now will display the user=<userid> for this thread context ...
      log.info("Successful execution of request");
      
      // user request processing is now finished, no need to log our current user anymore
      MDC.remote("user");
    }
  }
```

Note that the _MDC_ system doesn't play nice with asynchronous logging scheme, like [Akka](http://akka.io/)'s logging system. Because the MDC is kept in a per-thread storage area and in asynchronous systems you don't have the guarantee that the thread doing the log write is the one that has the MDC. In such situation, you need to log the context manually with every log statement.

## 7. Thou shalt log in machine parseable format

Log entries are really good for human, but very poor for machines. Sometimes it is not enough to manually read log files, you need to perform some automated processing (for instance for alerting or auditing). Or you want to store centrally your logs and be able to perform search requests.

So what happens when you embed the log context in the string like in this hypothetical logging statement:

```java
log.info("User {} plays {} in game {}", userId, card, gameId);
```

This will produce this kind of text:

```
2013-01-12 17:49:37,656 [T1] INFO  c.d.g.UserRequest  User 1334563 plays 4 of spades in game 23425656
```

Now, if you want to parse this, you'd need the following (untested) regex:

```
  /User (\d+) plays (.+?) in game (\d+)$/
```

Well, this is not easy and very error-prone, just to get access to string parameters your code already knows natively.

So what about this idea, I believe [Jordan Sissel](http://www.semicomplete.com/) first introduced in his ruby-cabin library:
Let add the context in a _machine parseable format_ in your log entry. Our aforementioned example could be using JSON like this:

```
2013-01-12 17:49:37,656 [T1] INFO  c.d.g.UserRequest  User plays {'user':1334563, 'card':'4 of spade', 'game':23425656}
```

Now your log parsers can be much easier to write, indexing now becomes straightforward and you can enable all [logstash](http://logstash.net/) power.

## 8. Thou shalt not log too much or too little

That might sound stupid, but there is a right balance for the amount of log. 

Too much log and it will really become hard to get any value from it. When manually browsing such logs, there is too much clutter which when trying to troubleshoot a production issue at 3AM is not a good thing.

Too little log and you risk to not be able to troubleshoot problems: troubleshooting is like solving a difficult puzzle, you need to get enough material for this.

Unfortunately there is no magic rule when coding to know what to log. It is thus very important to strictly respect the 1st and 2nd commandments so that when the application will be live it will be easier to increase or decrease the log verbosity.

One way to overcome this issue is during development to log as much as possible (do not confuse this with logging added to debug the program). Then when the application enters production, perform an analysis of the produced logs and reduce or increase the logging statement accordingly to the problems found. Especially during troubleshooting, note the part of the application you wished you could have more context or logging, and make sure to add those log statements to the next version (if possible at the same time you fix the issue to keep the problem fresh in memory). Of course that requires an amount of communication between ops and devs.

This can be a complex task, but I would recommend to refactor logging statements as much as you refactor the code. The idea would be to have a tight feedback loop between the production logs and the modification of such logging statement. It's even more efficient if your organization has a continuous delivery process in place, as the refactoring can be constant.

Logging statements are some kind of code metadata, at the same level of code comments. It's really important to keep the logging statements in sync with the code. There's nothing worst when troubleshooting issues to get irrelevant messages that have no relation to the code processed.

## 9. Thou shalt think to the reader

Why adding logging to an application?

The only answer is that someone will have to read it one day or later (or what is the point?). More important it is interesting to think about who will read those lines.
Depending on the person you think will read the log messages you're about to write, the log message content, context, category and level will be quite different.

Those persons can be:

* an end-user trying to troubleshoot herself a problem (imagine a client or desktop program)
* a system-administrator or operation engineer troubleshooting a production issue
* a developer either for debugging during development or solving a production issue

Of course the developer knows the internals of the program, thus her log messages can be much more complex than if the log message is to be addressed to an end-user. So adapt your language to the intended target audience, you can even dedicate separate categories for this.

## 10. Thou shalt not log only for troubleshooting

As the log messages are for a different audience, log messages will be used for different reasons.
Even though troubleshooting is certainly the most evident target of log messages, you can also use log messages very efficiently for:

* _Auditing_: this is sometimes a business requirement. The idea is to capture significant events that matter to the management or legal people. These are statements that describe usually what users of the system are doing (like who signed-in, who edited that, etc...).

* _Profiling_: as logs are timestamped (sometimes to the millisecond level), it can become a good tool to profile sections of a program, for instance by logging the start and end of an operation, you can either automatically (by parsing the log) or during troubleshooting infer some performance metrics without adding those metrics to the program itself.

* _Statistics_: if you log each time a certain event happens (like a certain kind of error or event) you can compute interesting statistics about the running program (or the user behaviors). It's also possible to hook this to an alert system that can detect too many errors in a row.

## Conclusion

I hope this will help you produce more useful logs, and bear with me if I forgot an essential (to you) commandments. Oh and I can't be held responsible if your log doesn't get better after reading this blog :)

It's possible that those 10 commandments are not enough, so feel free to use the comment section (or twitter or your own blog) to add more useful tips.

Thanks for reading.
