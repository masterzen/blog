--- 

title: February Puppet Dev Call
date: 2009-02-05 20:39:46 +01:00
comments: true
wordpress_id: 18
wordpress_url: http://www.masterzen.fr/?p=18
categories: 
- Programming
- System Administration
- Puppet
tags: 
- puppet
- dev call
- development
- roadmap
---
Yesterday we had the [February Puppet Dev Call](http://madstop.com/2009/02/05/summary-of-february-2009-puppet-developer-call/) 
with unfortunately poor audio, lots of [Skype](http://www.skype.com/) disconnections which for a 
non native English speaker like me rendered the call difficult to follow (what is strange is that the 
one I could hear the best was [Luke](http://reductivelabs.com/trac/puppet "Luke Kanies, Puppet creator"))

[![Puppet, brought to you by Reductive Labs](http://reductivelabs.com/images/puppet-short.png)](http://reductivelabs.com/trac/puppet)

But that was an important meeting, as we know how the [_development process_](http://reductivelabs.com/trac/puppet/wiki/DevelopmentLifecycle) will 
continue from now on. It was agreed (because it makes real sense) to have 
the **master as current stable** and fork a **'next' branch** for on-going development 
of the next version.

The idea is that newcomers will just have to git clone the repository to 
produce a bug fix or stable feature, without having to wonder (or 
[read the development process wiki page](http://reductivelabs.com/trac/puppet/wiki/DevelopmentLifecycle)) where/how 
to get the code.

It was also decided that [0.25](http://projects.reductivelabs.com/versions/show/3) was really imminent with a 
planned release date later this month. 

Arghhh, this doesn't leave me lots of time to finish the [Application Controller stuff I'm currently working on](http://github.com/masterzen/puppet/tree/wip/appcontroller). The issue is that I procrastinated  a little bit with the [storeconfigs speed-up patch](http://github.com/masterzen/puppet/tree/features/storeconfigs-opt) (which I hope will be merged for 0.25), and [a few important 0.24.x bug fixes](http://github.com/masterzen/puppet/tree/tickets/0.24.x/1922).

There was also a discussion about what should be part of the Puppet core and what shouldn't (like the recent [zenoss](http://www.zenoss.com/community/open-source-network-monitoring-software/) patch). _Digression: I'm considering doing an [OpenNMS](http://www.opennms.org/index.php/Main_Page) type/provider like the Zenoss or Nagios one_. 

Back to the real topic. It was proposed to have a repository of non-core features, 
but this essentially only creates more troubles, including but not limited to:

- _Versioning _of interdependent modules
- Modules _dependencies_
- Modules _distribution_
- Testing (how do you run exhaustive tests if everything is scattered ?)
- Reponsability

Someone suggested (sorry can't remember who) that we need a _packaging system_ to fill this hole, but I don't 
think it is satisfactory. I understand the issue, but have no immediate answer to this question (that's why I didn't 
comment on this topic during the call).

Second digression: if you read this and want to contribute to Puppet (because that's a wonderful software, 
a great developer team, a nicely and well-done codebase), I can't stress you too much to read the
following wiki pages:

- [Development lifecyle](http://reductivelabs.com/trac/puppet/wiki/DevelopmentLifecycle)
- [How to write unit tests](http://reductivelabs.com/trac/puppet/wiki/WritingTests) (yes no development without tests)

Also come by to [#puppet](http://reductivelabs.com/trac/puppet/wiki/IrcChannel) and/or
the [puppet-dev google groups](http://groups.google.com/group/puppet-dev), we're ready to help!
