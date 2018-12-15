--- 

title: Puppet Extension Points - part 1
date: 2011-10-29 12:17:23 +02:00
wordpress_id: 237
wordpress_url: http://www.masterzen.fr/?p=237
comments: true
category: 
- Ruby
- System Administration
- Puppet
tags: 
- Ruby
- puppet
- DSL
- metaprogramming
- pluginsync
- internals
---
It's been a long time since my [last blog post](http://www.masterzen.fr/2010/11/14/puppet-ssl-explained/), almost a year. Not that I stopped hacking on Puppet or other things (even though I'm not as productive as I had been in the past), it's just that so many things happened last year ([Memoir'44](http://www.daysofwonder.com/memoir44-online) release, architecture work at [Days of Wonder](http://www.daysofwonder.com/)) that I lost the motivation of maintaining this blog.

But _that's over,_ I plan to start a series of **Puppet internals articles**. The first one (yes this one) is devoted to Puppet Extension Points.

Since a long time, Puppet contains a system to _dynamically load ruby fragments_ to provide new functionalities both for the client and the master. Among the available extension points you'll find:

- manifests functions
- custom facts
- types and providers
- faces


Moreover, Puppet contains a [synchronization mechanism ](http://docs.puppetlabs.com/guides/plugins_in_modules.html)that allows you to ship your extensions into your manifests modules and those will be replicated automatically to the clients. This system is called **pluginsync**.

This first article will first dive into the ruby meta-programming used to create (some of) the extension DSL (not to be confused with the Puppet DSL which is the language used in the manifests). We'll talk a lot about DSL and ruby meta programming. If you want to know more on those two topics, I'll urge you to read those books:

- [Domain Specific Languages](http://www.amazon.com/gp/product/0321712943) - Martin Fowler
- [Metaprogramming Ruby: Program Like the Ruby Pros](http://www.amazon.com/Metaprogramming-Ruby-Program-Like-Pros/dp/1934356476) - Paolo Perrotta

## Anatomy of a simple extension

Let's start with the simplest form of extension: _Parser Functions_.

Functions are extensions of the _Puppet Parser_, the entity that reads and analyzes the puppet DSL (ie the manifests). This language contains a structure which is called "function". You already use them a lot, for instance "include" or "template" are functions.

When the parser analyzes a given manifest, it detects the use of functions, and later on during the compilation phase the function code is executed and the result may be injected back into the compilation.

Here is a simple function:

{% gist 1324327 basename.rb %}

The given function uses the puppet functions DSL to load the extension code into Puppet core code.  This function is simple and does what its basename shell equivalent does: stripping leading paths in a given filename.  For this function to work you need to drop it in the ``lib/puppet/parser/functions`` directory of your module.  Why is that? It's because after all, extensions are written in ruby and integrate into the Puppet ruby namespace. Functions in puppet live in the [Puppet::Parser::Functions](https://github.com/puppetlabs/puppet/blob/2.7.x/lib/puppet/parser/functions.rb) class, which itself belongs to the Puppet scope.

The [Puppet::Parser::Functions](https://github.com/puppetlabs/puppet/blob/2.7.x/lib/puppet/parser/functions.rb) class in Puppet core has the task of _loading all functions_ defined in any ``puppet/parser/functions`` directories it will be able to find in the whole _ruby load path_. When Puppet uses a module, the modules' lib directory is automatically added to the ruby load path.  Later on, when parsing manifests and a function call is detected, the [Puppet::Parser::Functions](https://github.com/puppetlabs/puppet/blob/2.7.x/lib/puppet/parser/functions.rb) will try to load all the ruby files in all the ``puppet/parser/functions`` directory available in the ruby load path. This last task is done by the Puppet autoloader (available into [Puppet::Util::Autoload](https://github.com/puppetlabs/puppet/blob/2.7.x/lib/puppet/util/autoload.rb)).  Let's see how the above code is formed:


- _Line 1_: this is ruby way to say that this file belongs to the puppet function namespace, so that [Puppet::Parser::Functions](https://github.com/puppetlabs/puppet/blob/2.7.x/lib/puppet/parser/functions.rb) will be able to load it. In real, we're opening the ruby class [Puppet::Parser::Functions](https://github.com/puppetlabs/puppet/blob/2.7.x/lib/puppet/parser/functions.rb), and all that will follow will apply to this specific puppet class.

- _Line 2_: this is where ruby meta-programming is used. Translated to standard ruby, we're just calling the "newfunction" method. Since we're in the Puppet::Parser::Functions class, we in fact are just calling the class method [Puppet::Parser::Functions#newfunction](https://github.com/puppetlabs/puppet/blob/2.7.x/lib/puppet/parser/functions.rb#L38).

 We pass to it 4 arguments:
	
  - _the function name_, encoded as a symbol. Functions name should be unique in a given environment
  - _the function type_: either your function is a rvalue (meaning a right-value, an entity that lies on the right side of an assignment operation, so in real English: a function that returns a value), or is not (in which case the function is just a side-effect function not returning any values).
  - _a documentation string_ (here we used a ruby heredoc) which might be extracted later.
  - and finally we're passing a _ruby code block_ (from the do on line 5, to the inner end on line 10). This code block won't be executed when puppet loads the functions.

- _Line 5 to 10_. The body of the methods. When ruby loads the function file on behalf of Puppet, it will happily pass the code block to newfunction. This last one will store the code block for later use, and make it available in the Puppet scope class under the name **function_basename** (that's one of the cool thing about ruby, you can arbitrarily create new methods on classes, objects or even instances).


So let's see what happens when puppet parses and executes the following manifest:


{% gist 1324327 basename.pp %}

The first thing that happens when compiling manifests is that the Puppet **lexer** triggers. It will read the manifest content and _split it in tokens_ that the parser knows. So essentially the above content will be transformed in the following stream of tokens:

{% gist 1324327 basename-token-stream.txt %}

The parser, given this input, will reduce this to what we call an [Abstract Syntax Tree](http://en.wikipedia.org/wiki/Abstract_syntax_tree). That's a memory data structure (usually a tree) that represents the orders to be executed that was derived from the language grammar and the stream of tokens. In our case this will schematically be parsed as: 

{% gist 1324327 basename-ast.txt %}

In turns, when puppet will compile the manifest (ie execute the above AST), this will be equivalent to this ruby operation:

{% gist 1324327 basename-call.rb %}

Remember how [Puppet::Parser::Functions#newfunction](https://github.com/puppetlabs/puppet/blob/2.7.x/lib/puppet/parser/functions.rb#L38) created the _function_basename_. At that time I didn't really told you the exact truth. In fact _newfunction_ creates a function in an environment specific object instance (so that functions can't leak from one Puppet environment to another, which was one of the problem of 0.25.x). And any given Puppet scope which are instances of [Puppet::Parser::Scope](https://github.com/puppetlabs/puppet/blob/2.7.x/lib/puppet/parser/scope.rb) when constructed will mix in this environment object, and thus bring to life our shiny function as if it was defined in the scope ruby code itself.

## Pluginsync


Let's talk briefly about the way your modules extensions are propagated to the clients. So far we've seen that functions live in the master, but some other extensions types (like facts or types) essentially live in the client.  Since it would be cumbersome for an admin to replicate all the given extensions to all the clients manually, Puppet offers _[pluginsync](http://docs.puppetlabs.com/guides/plugins_in_modules.html)_, a way to distribute this ruby code to the clients.  It's part of every puppet agent run, before asking for a catalog to the master.  The interesting thing (and that happens in a lot of place into Puppet, which always amazes me), is that this pluginsync process is using Puppet itself to perform this synchronization.  Puppet is good at synchronizing remotely and recursively a set of files living on the master. So pluginsync just create a small catalog containing a recursive File resource whose source is the plugins fileserver mount on the master, and the destination the current agent puppet lib directory (which is part of the ruby load path).  Then this catalog is evaluated and the Puppet File resource mechanism does its magic and creates all the files locally, or synchronizes them if they differ.  Finally, the agent loads all the ruby files it synchronized, registering the various extensions it contains, before asking for its host catalog.

## Wants some facts?


The other extension point that you certainly already encountered is adding [custom facts](http://docs.puppetlabs.com/guides/custom_facts.html).  A fact is simply a _key, value tuple_ (both are strings). But we also usually call a fact the method that dynamically produces this tuple.  Let's see what it does internally. We'll use the following example custom fact:

{% gist 1324327 hardware_platform.rb %}  

It's no secret that Puppet uses [Facter](http://puppetlabs.com/puppet/related-projects/facter/) a lot. When a puppet agent wants a catalog, the first thing it does is asking _Facter_ for a set of facts pertaining to the current machine. Then those facts are sent to the master when the agent asks for a catalog. The master **injects those facts as variables** in the root scope when compiling the manifests.

So, facts are executed in the agent. Those are _pluginsync'ed_ as explained above, then loaded into the running process.

When that happens the add method of the [Facter class](https://github.com/puppetlabs/facter/blob/1.6.1/lib/facter.rb) is called. The block defined between _line 2 and 6_ is then executed in the [Facter::Util::Resolution](https://github.com/puppetlabs/facter/blob/1.6.1/lib/facter/util/resolution.rb) context. So the [Facter::Util::Resolution#setcode](https://github.com/puppetlabs/facter/blob/1.6.1/lib/facter/util/resolution.rb#L116) method will be called and the block between _line 3 and 5_ will be stored for later use.

This Facter::Util::Resolution instance holding our fact code will be in turn stored in the facts collection under the name of the fact (see _line 2_).

Why is it done in this way? Because not all facts can run on every hosts. For instance our above facts does not work on Windows platform. So we should use facter way of _confining_ our facts to architectures on which we know they'll work.
Thus Facter defines a set of methods like "confine" that can be called during the call of Facter#add (just add those outside of the setcode block).  Those methods will modify how the facts collection will be executed later on. It wouldn't have been possible to confine our facts if we stored the whole Facter#add block and called it directly at fact resolution, hence the use of this two-steps system.

## Conclusion

And, that's all folks for the moment. Next episode will explain types and providers inner workings. I also plan an episode about other Puppet internals, like the parser, catalog evaluation, and/or the indirector system.

Tell me (though comments here or through my twitter handle [@_masterzen_](http://twitter.com/#!/_masterzen_)) if you're interested in this kind of Puppet stuff, or if there are any specific topics you'd like me to cover :)
