--- 

title: Puppet Extension Points - part 2
date: 2011-11-02 21:00:56 +01:00
wordpress_id: 242
wordpress_url: http://www.masterzen.fr/?p=242
comments: true
category: 
- Ruby
- Puppet
- System Administration
tags: 
- provider
- type
- RAL
- internals
- metaprogramming
- DSL
- puppet
- Ruby
- DNS
---
After the [first part in this series](http://www.masterzen.fr/2011/10/29/puppet-extension-points-part-1/) of article on Puppet extensions points, I'm proud to deliver a new episode focusing on [Types](http://projects.puppetlabs.com/projects/1/wiki/Development_Practical_Types) and [Providers](http://projects.puppetlabs.com/projects/puppet/wiki/Development_Provider_Development).

Note that there's a really good chapter on the same topic in [James Turnbull and Jeff McCune Pro Puppet](http://www.amazon.com/Pro-Puppet-James-Turnbull/dp/1430230576) (which I highly recommend if you're a serious puppeteer). Also note that you can attend [Puppetlabs Developper Training](http://puppetlabs.com/services/training-workshops/), which covers this topic.

## Of Types and Providers

One of the great force of Puppet is how various heterogenous aspects of a given POSIX system (or not, like the [Network Device system](http://puppetlabs.com/blog/puppet-network-device-management/) I contributed) are abstracted into simple elements: **types**.

_Types_ are the foundation bricks of Puppet, you use them everyday to model how your systems are formed. Among the core types, you'll find user, group, file, ...

In Puppet, manifests define resources which are _instances of their type_. There can be only one resource of a given name (what we call the _namevar_, _name_ or _title_) for a given catalog (which usually maps to a given host).

A type models what facets of a physical entity (like a host user) are managed by Puppet. These model facets are called "properties" in Puppet lingo.

Essentially a type is a name, some properties to be managed and some parameters. Paramaters are values that will help or direct Puppet to manage the resource (for instance the managehome parameter of the [user type](http://docs.puppetlabs.com/references/2.7.5/type.html#user) is not part of a given user on the host, but explains to Puppet that this user's home directory is to be managed).

### Let's follow the life of a resource during a puppet run.

1. During compilation, the puppet parser will instantiate [Puppet::Parser::Resource](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/parser/resource.rb) instances which are [Puppet::Resource](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/resource.rb) objects. Those contains the various properties and parameters values defined in the manifest.

2. Those resources are then inserted into the catalog (an instance of [Puppet::Resource::Catalog](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/resource/catalog.rb))

3. The catalog is then sent to the agent (usually in json format)

4. The agent converts the catalog individual resources into RAL resources by virtue of Puppet::Resource#to_ral. We're now dealing with instances of the real puppet type class. RAL means Resource Abstraction Layer.

	5. The agent then applies the catalog. This process creates the relationships graph so that we can manage resources in an order obeying require/before metaparameters. During catalog application, every RAL resource is evaluated. This process tells a given type to do what is necessary so that every managed property of the real underlying resource match what was specified in the manifest. The software system that does this is the _provider_.



So to summarize, a type defines to Puppet what properties it can manage and an accompanying provider is the process to manage them. Those two elements forms the Puppet RAL.

There can be more than one provider per type, depending on the host or platform. For instance every users have a login name on all kind of systems, but the way to create a new user can be completely different on Windows or Unix. In this case we can have a provider for Windows, one for OSX, one for Linux... Puppet knows how to select the best provider based on the facts (the same way you can confine facts to some operating systems, you can confine providers to some operating systems).

## Looking Types into the eyes

I've written a combination of types/providers for this article. It allows to manage DNS zones and DNS Resource Records for DNS hosting providers (like [AWS Route 53](http://aws.amazon.com/route53/) or [Zerigo](http://www.zerigo.com/managed-dns)). To simplify development I based the system on [Fog](http://fog.io/1.0.0/dns/) DNS providers (you need to have the Fog gem installed to use those types on the agent). The full code of this system is available in my [puppet-dns github repository](https://github.com/masterzen/puppet-dns).

This work defines two new Puppet types:

- _dnszone:_ manage a given DNS zone (ie a domain)
- _dnsrr: _manage an individual DNS RR (like an A, AAAA, ... record). It takes a name, a value and a type.


Here is how to use it in a manifest:

{% gist 1328479 dns.pp %}  

Let's focus on the **dnszone** type, which is the simpler one of this module: 

{% gist 1328479 dnszone.rb %}  

Note, that the dnszone type assumes there is a ``/etc/puppet/fog.yaml`` file that contains Fog DNS options and credentials as a hash encoded in yaml. Refer to the aforementioned github repository for more information and use case.

Exactly like parser functions, types are defined in ruby, and Puppet can autoload them. Thus types should obey to the Puppet type ruby namespace. That's the reason we have to put types in ``puppet/type/``.  Once again this is ruby metaprogramming (in its all glory), to create a specific internal DSL that helps describe types to Puppet with simple directives (the alternative would have been to define a datastructure which would have been much less practical).

Let's dive into the _dnszone_ type.

- _Line 1,_ we're calling the [Puppet::Type](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/type.rb)#newtype method passing, first the type name as a ruby symbol (which should be unique among types), second a block (from _line 1 to the end_). The newtype method is imported in [Puppet::Type](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/type.rb) but is in fact defined in [Puppet::Metatype::Manager](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/metatype/manager.rb). _Newtype_ job is to create a new singleton class whose parent is [Puppet::Type](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/type.rb) (or a descendant if needed). Then the given block will be evaluated in class context (this means that the block is executed with ``self`` being the just created class). This singleton class is called ``Puppet::TypeDnszone`` in our case (but you see the pattern).

- _Line 2_: we're assigning a string to the [Puppet::Type](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/type.rb) class variable ``@doc``. This will be used to to extract type documentation.

- _Line 4_: This straight word ``ensurable``, is a class method in [Puppet::Type](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/type.rb). So when our type block is evaluated, this method will be called. This methods installs a new special property Ensure. This is a shortcut to automatically manage creation/deletion/existence of the managed resource. This automatically adds support for ``ensure =&gt; (present|absent)`` to your type. The provider still has to manage ensurability, though.

- _Line 6:_ Here we're calling [Puppet::Type](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/type.rb)#newparam. This tells our type that we're going to have a parameter called "name". Every resource in Puppet must have a unique key, this key is usually called the name or the title. We're giving a block to this newparam method. The job of newparam is to create a new class descending of [Puppet::Parameter](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/parameter.rb), and to evaluate the given block in the context of this class (which means in this block self is a singleton class of [Puppet::Parameter](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/parameter.rb)). [Puppet::Parameter](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/parameter.rb) defines a bunch of utility class methods (that becomes apparent directives of our parameter DSL), among those we can find ``isnamevar`` which we've used for the name parameter. This tells Puppet type system that the name parameter is what will be the holder of the unique key of this type. The desc method allows to give some documentation about the parameter.

- _Line 12_: we're defining now the email parameter. And we're using the ``newvalues`` class method of [Puppet::Parameter](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/parameter.rb). This method defines what possible values can be set to this parameter. We're passing a regex that allows any string containing an '@', which is certainly the worst regex to validate an e-mail address :) Puppet will raise an error if we don't give a valid value to this parameter.

- _Line 17_: and again a new parameter. This parameter is used to control Fog behavior (ie give to it your credential and fog provider used). Here we're using ``defaultto``, which means if we don't pass a value then the defaultto value will be used.

- _Line 22_: there is a possibility for a given resource to auto-require another resource. The same way a file resource can automatically add 'require' to its path ancestor. In our case, we're autorequiring the yaml_fog_file, so that if it is managed by puppet, it will be evaluated before our dnszone resource (otherwise our fog provider might not have its credentials available).


Let's now see another type which uses some other type DSL directives:

{% gist 1328479 dnsrr.rb %}  

We'll pass over the bits we already covered with the first type, and concentrate on new things:

- _Line 12_: our _dnszone_ type contained only parameters. Now it's the first time we define a **property**. A property is exactly like a parameter but is fully managed by Puppet (see the chapter below). A property is an instance of a [Puppet::Property](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/type.rb) class, which itself inherits from [Puppet::Parameter](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/parameter.rb), which means all the methods we've covered in our first example for parameters are available for properties. This type property is interesting because it defines discrete values. If you try to set something outside of this list of possible values, Puppet will raise an error. Values can be either ruby symbols or strings.

- _Line 17_: a new property is defined here. With the ``isrequired`` method we tell Puppet that is is indeed necessary to have a value. And the validate methods will store the given validate block so that when Puppet will set the desired value to this property it will execute it. In our case we'll report an error if the given value is empty.

- _Line 24_: here we defined a global validation system. This will be called when all properties will have been assigned a value. This block executes in the instance context of the type, which means that we can access all instance variables and methods of [Puppet::Type](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/type.rb) (in particualy the [] method that allows to access parameters/properties values). This allows to perform validation across the boundaries of a given parameter/property.

- _Line 25_: finally, we declare a new parameter that references a _dnszone_. Note that we use a dynamic _defaultto_ (with a block), so that we can look up the given resource name and derive our zone from the FQDN. This raises an important feature of the type system: _the order of the declarations of the various blocks is important_. Puppet will always respect the declaration order of the various properties when evaluating their values. That means a given property can access a value of another properties defined earlier.


I left managing RR TTL as an exercise to the astute reader :)  Also note we didn't cover all the directives the type DSL offers us. Notably, we didn't see value munging (which allows to transform a string representation coming from the manifest to an internal (to the type) format). For instance that can be used to transform string IP address to the ruby IPAddr type for later use.  I highly recommend you to browse the default types in the Puppet source distribution and check the various directives used there. You can also read [Puppet::Parameter](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/parameter.rb), [Puppet::Property](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/property.rb) and [Puppet::Type](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/type.rb) source code to see the ones we didn't cover.

## Life and death of Properties


So, we saw that a [Puppet::Parameter](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/parameter.rb) is just a holder for the value coming from the manifest. A [Puppet::Property](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/property.rb) is a parameter that along with the desired value (the one coming from the manifest) contains the current value (the one coming from the managed resource on the host).  The first one is called the "should", and the later one is called the "value". Those innocently are methods of the Puppet::Property object and returns respectively those values.  A property implements the following aspects:


- it can ``retrieve`` a value from the managed resource. This is the operation of asking the real host resource to fetch its value. This is usually performed by delegation to the provider.

- it can report its ``should`` which is the value given in the manifest

- it can be ``insync?``. This returns true if the retrieved value is equal to the "should" value.

- and finally it might ``sync``. Which means to the necessary so that "insync?" becomes true. If there is a provider for the given type, this one will be called to take care of the change.



When Puppet manages a resource, it does it with the help of a [Puppet::Transaction](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/transaction.rb). The given transaction orders the various properties that are not _insync?_ to _sync_. Of course this is a bit more complex than that, because this is done while respecting resource ordering (the one given by the require/before metaparameter), but also propagating change events (so that service can be restarted and so on), and allowing resources to spawn child resources, etc...  It's perfectly possible to write a type without a provider, as long as all properties used implement their respective retrieve and sync methods. Some of the core types are doing this.

## Providers


We've seen that properties usually delegate to the providers for managing the underlying real resource. In our example, we'll have two providers, one for each defined type.  There are two types of providers:


- prefetch/flush
- per properties



The _per properties_ providers needs to implement a getter and a setter for every property of the accompanying type.  When the transaction manipulates a given property its provider getter is called, and later on the setter will be called if the property is not _insync?_. It is the responsibility of those setters to flush those values to the physical managed resource.  For some providers it is highly impractical or inefficient to flush on every property value change. To solve this issue, a given provider can be a _prefetch/flush_ one.  A _prefetch/flush_ provider implements only two methods:


- ``prefetch``, which given a list of resources will in one call return a set of provider instances filled with the value fetched from the real resource.
- ``flush`` will be called after all values will have been set, and that they can be persisted to the real resource.


The two providers I've written for this article are _prefetch/flush_ ones, because it was impractical to call Fog for every property.

## Anatomy of the _dnszone_ provider


We'll focus only on this provider, and I'll leave as an exercise to the reader the analysis of the second one.  Providers, being also ruby extensions, must live in the correct path respecting their ruby namespaces. For our dnszone fog provider, it should be in the ``puppet/provider/dnszone/fog.rb`` file.  Unlike what I did for the types, I'll split the provider code in parts so that I can explain them with the context. You can still [browse the whole code](https://github.com/masterzen/puppet-dns/blob/master/lib/puppet/provider/dnszone/fog.rb).

{% gist 1328479 dnszone-fog-provider-1.rb %}  

This is how we tell Puppet that we have a new provider for a given type. If we decipher this, we're fetching the dnszone type (which returns the singleton class of our dnszone type), and call the class method "provide", passing it a name, some options and a big block. In our case, the provider is called "fog", and our parent should be [Puppet::Provider::Fog](https://github.com/masterzen/puppet-dns/blob/master/lib/puppet/provider/fog.rb) (which defines common methods for both of our fog providers, and is also a descendant of [Puppet::Provider](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/provider.rb)).  Like for types, we have a _desc_ class method in [Puppet::Provider](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/provider.rb) to store some documentation strings.  We also have the confine method. This method will help Puppet choose the correct provider for a given type, ie its suitability. The confining system is managed by [Puppet::Provider::Confiner](https://github.com/puppetlabs/puppet/blob/2.7.6/lib/puppet/provider/confiner.rb). You can use:

- a fact or puppet settings value, as in: ``confine :operatingsystem =&gt; :windows``
- a file existence: ``confine :exists =&gt; "/etc/passwd"``
- a Puppet "feature", like we did for testing the fog library presence
- an arbitrary boolean expression ``confine :true =&gt; 2 == 2``


A provider can also be the default for a given fact value. This allows to make sure the correct provider is used for a given type, for instance the apt provider on debian/ubuntu platforms.

And to finish, a provider might need to call executables on the platform (and in fact most of them do). The Puppet::Provider class defines a shortcut to declare and use those executables easily:
{% gist 1328479 commands.rb %}  

Let's continue our exploration of our _dnszone_ provider  

{% gist 1328479 dnszone-fog-provider-2.rb %}   

``mk_resource_methods`` is an handy system that creates a bunch of setters/getters for every parameter/properties for us. Those fills values in the ``@property_hash hash``.  

{% gist 1328479 dnszone-fog-provider-3.rb %}   

The prefetch methods calls _fog_ to fetch all the DNS zones, and then we match those with the ones managed by Puppet (from the resources hash).
 
For each match we instantiate a provider filled with the values coming from the underlying physical resource (in our case fog). For those that don't match, we create a provider whose only existing properties is that ensure is absent.  

{% gist 1328479 dnszone-fog-provider-4.rb %}   

Flush does the reverse of prefetch. Its role is to make sure the real underlying resource conforms to what Puppet wants it to be.

There are 3 possibilities:

- the desired state is _absent_. We thus tell fog to destroy the given zone.
- the desired state is _present_, but during prefetch we didn't find the zone, we're going to tell fog to create it.
- the desired state is _present_, and we could find it during prefetch, in which case we're just refreshing the fog zone.


{% gist 1328479 dnszone-fog-provider-5.rb %}

To my knowledge this is used only for ralsh (puppet resource). The problem is that our provider can't know how to access fog until it has a dnszone (which creates a chicken and egg problem :)
 
And finally we need to manage the Ensure property which requires our provider to implement: create, destroy and exists?.

{% gist 1328479 dnszone-fog-provider-6.rb %} 

In a _prefetch/flush provider_ there's no need to do more than controlling the ensure value.

Things to note:

- a provider instance can access its resource with the ``resource`` accessor
- a provider can access the current catalog through its ``resource.catalog`` accessor. This allows as I did in the ``dnsrr/fog.rb`` provider to retrieve a given resource (in this case the _dnszone_ a given _dnsrr_ depends to find how to access a given zone through fog).


## Conclusion

We just surfaced the provider/type system (if you read everything you might disagree, though).

For instance we didn't review the parsed file provider which is a beast in itself (the Pro Puppet book has a section about it if you want to learn how it works, the Puppet core host type is also a parsed file provider if you need a reference).

Anyway make sure to read the Puppet core code if you want to know more :) feel free to ask questions about Puppet on the [puppet-dev mailing list](http://groups.google.com/group/puppet-dev) or on the #puppet-dev irc channel on freenode, where you'll find me under the _masterzen_ nick.

And finally expect a little bit of time before the next episode, which will certainly cover the Indirector and how to add new terminus (but I first need to find an example, so suggestions are welcome).

