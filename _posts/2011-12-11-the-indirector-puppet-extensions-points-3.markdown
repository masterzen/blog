---

title: The Indirector - Puppet Extension Points 3
date: 2011-12-11 11:34
comments: true
category:
- Puppet
- Sysadmin
tags: 
- puppet
- indirector
- internals
- metaprogramming
- DSL
- Ruby
---

This article is a follow-up of those previous two articles of this series on Puppet Internals:

 - [Puppet parser functions and custom facts](/2011/10/29/puppet-extension-points-part-1/)
 - [Puppet types and providers](/2011/11/02/puppet-extension-point-part-2/)

Today we'll cover the **The Indirector**. I believe that at the end of this post, you'll know exactly what is the indirector and how it works.

## The scene

The puppet source code needs to deal with lots of different abstractions to do its job. Among those abstraction you'll find:

 - Certificates
 - Nodes
 - Facts
 - Catalogs
 - ...

Each one those abstractions can be found in the Puppet source code under the form of a _model class_. For instance when Puppet needs to deal with the current node, it in fact deals with an _instance_ of the node model class. This class is called [`Puppet::Node`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/node.rb).

Each model can exist physically under different forms. For instance _Facts_ can come from _Facter_ or a _YAML file_, or _Nodes_ can come from an _ENC_, _LDAP_, _site.pp_ and so on. This is what we call a **Terminus**.

The _Indirector_ allows the Puppet programmer to deal with model instances without having to manage herself the gory details of where this model instance is coming/going.

For instance, the code is the same for the client call site to find a node when it comes from an ENC or LDAP, because it's irrelevant to the client code.

## Actions

So you might be wondering what the _Indirector_ allows to do with our models. Basically the _Indirector_ implements a basic CRUD (Create, Retrieve, Update, Delete) system. In fact it implements 4 verbs (that maps to the CRUD and REST verb sets):

- _Find_: allows to retrieve a specific instance, given through the `key`
- _Search_: allows to retrieve some instances with a search term
- _Destroy_: remove a given instance
- _Save_: stores a given instance

You'll see a little bit later how it is wired, but those verbs exist as class and/or instance methods in the models class.

So back to our [`Puppet::Node`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/node.rb) example, we can say this:

``` ruby
  # Finding a specific node
  node = Puppet::Node.find('test.daysofwonder.com')
  
  # here I can use node, being an instance of Puppet::Node
  puts "node: #{node.name}"
  
  # I can also save the given node (if the terminus allows it of course)
  # Note: save is implemented as an instance method
  node.save
  
  # we can also destroy a given node (if the terminus implements it):
  Puppet::Node.destroy('unwanted.daysowonder.com')
```

And this works for all the managed models, I could have done the exact same code with certificate instead of nodes.

## Terminii

For the Latin illiterate out-there, terminii is the latin plural for terminus.

So a terminus is a concrete class that knows how to deal with a specific model type. A terminus exists only for a given model. For instance the catalog indirection can use the Compiler or the YAML terminus among half-dozen of available terminus.

The _terminus_ is a class that should inherit somewhere in the class hierarchy from [`Puppet::Indirector::Terminus`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector/terminus.rb). This last sentence might be obscure but if your terminus for a given model directly inherits from [`Puppet::Indirector::Terminus`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector/terminus.rb), it is considered as an abstract terminus and won't work.

``` ruby
  def find(request)
    # request.key contains the instance to find
  end

  def destroy(request)
  end

  def search(request)
  end

  def save(request)
    # request.instance contains the model instance to save
  end
```

The `request` parameter used above is an instance of [`Puppet::Indirector::Request`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector/request.rb). This request object contains a handful property that might be of interest when implementing a terminus. The first one is the `key` method which returns the name of the instance we want to manipulate. The other is `instance` which is available only when saving is a concrete instance of the model.

### Implementing a terminus

To implement a new terminus of a given model, you need to add a ruby file of the terminus name in the `puppet/indirector/<indirection>/<terminus>.rb`.

For instance if we want to implement a new source of puppet nodes like storing node classes in DNS TXT resource records, we'd create a `puppet/node/dns.rb` file whose find method would ask for TXT RR using `request.key`.

Puppet already defines some common behavior like yaml based files, rest based, code based or executable based. A new terminus can inherit from one of those abstract terminus to inherit from its behavior.

I contributed (but hasn't been merged yet) and [OCSP](http://en.wikipedia.org/wiki/Online_Certificate_Status_Protocol) system for Puppet. This one defines a new indirection: `ocsp`. This indirection contains two terminus:

The real concrete one that inherits from [`Puppet::Indirector::Code`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector/code.rb), it in fact delegates the OCSP request verification to the OCSP layer:

``` ruby
require 'puppet/indirector/ocsp'
require 'puppet/indirector/code'
require 'puppet/ssl/ocsp/responder'

class Puppet::Indirector::Ocsp::Ca < Puppet::Indirector::Code
  desc "OCSP request revocation verification through the local CA."

  def save(request)
    Puppet::SSL::Ocsp::Responder.respond(request.instance)
  end
end
```

It also has a _REST terminus_. This allows for a given implementation to talk to a remote puppet process (usually a puppetmaster) using the indirector without modifying client or server code:

``` ruby
require 'puppet/indirector/ocsp'
require 'puppet/indirector/rest'

class Puppet::Indirector::Ocsp::Rest < Puppet::Indirector::REST
  desc "Remote OCSP certificate REST remote revocation status."

  use_server_setting(:ca_server)
  use_port_setting(:ca_port)
end
```

As you can see we can do a REST client without implementing any network stuff!

### Indirection creation

To tell Puppet that a given model class can be indirected it's just a matter or adding a little bit of Ruby metaprogramming.

To keep my OCSP system example, the OCSP request model class is declared like this:

``` ruby
class Puppet::SSL::Ocsp::Request < Puppet::SSL::Base
  ...
  
  extend Puppet::Indirector
  # this will tell puppet that we have a new indirection
  # and our default terminus will be found in puppet/indirector/ocsp/ca.rb
  indirects :ocsp, :terminus_class => :ca

  ...
end
```

Basically we're saying the our model `Puppet::SSL::Ocsp::Request` declares an indirection `ocsp`, whose default terminus class is `ca`. That means, if we straightly try to call `Puppet::SSL::Ocsp::Request.find`, the `puppet/indirection/ocsp/ca.rb` file will be used.

### Terminus selection

There's something I didn't talk about. You might ask yourself how Puppet knows which terminus it should use when we call one of the _indirector_ verb. As seen above, if nothing is done to configure it, it will default to the terminus given on the `indirects` call.

But it is configurable. The [`Puppet::Indirector`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector.rb) module defines the `terminus_class=` method. This methods when called can be used to change the active terminus.

For instance in the puppet agent, the catalog indirection has a REST terminus, but in the master the same indirection uses the compiler:

``` ruby
  # puppet agent equivalent code
  Puppet::Resource::Catalog.terminus_class = :rest
  
  # puppet master equivalent code
  Puppet::Resource::Catalog.terminus_class = :compiler
```

In fact the code is a little bit more complicated than this for the catalog but in the end it's equivalent.

There's also the possibility for a puppet application to specify a routing table between indirection and terminus to simplify the wiring.

### More than one type of terminii

There's something I left aside earlier. There are in fact two types of terminii per indirection:

- regular terminus as we saw earlier
- cache terminus

For every model class we can define the regular indirection terminus and an optional cache terminus.

Then when finding for an instance the cache terminus will first be asked for. If not found in the cache (or asked to not get from the cache) the regular terminus will be used. Afterward the instance will be `save`d in the cache terminus.

This cache is exploited in lots of place in the Puppet code base.

Among those, the `catalog` cache terminus is set to `:yaml` on the agent. The effect is that when the _agent_ retrieves the catalog from the master through the `:rest` regular terminus, it is locally saved by the yaml terminus. This way if the next agent run fails when retrieving the catalog through REST, it will used the previous one locally cached during the previous run.

Most of the certificate stuff is handled along the line of the catalog, with local caching with a file terminus.

### REST Terminus in details

There is a direct translation between the REST verbs and the indirection verbs. Thus the `:rest` terminus:

1. transforms the indirection and key to an URI: `/<environment>/<indirection>/<key>`
2. does an HTTP GET|PUT|DELETE|POST depending on the indirection verb

On the server side, the Puppet network layer does the reverse, calling the right indirection methods based on the URI and the _REST_ verb.

There's also the possibility to sends parameters to the indirection and with REST, those are transformed into URL request parameters.

The indirection name used in the URI is pluralized by adding a trailing 's' to the indirection name when doing a search, to be more REST. For example:

- `GET /production/certificate/test.daysofwonder.com` is find
- `GET /production/certificates/unused` is a search

When indirecting a model class, Puppet mixes-in the [`Puppet::Network::FormatHandler`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/network/format_handler.rb) module. This module allows to `render` and `convert` an instance from and to a serialized format. The most used one in Puppet is called `pson`, which in fact is json in disguised name.

During a REST transaction, the instance can be serialized and deserialized using this format. Each model can define its preferred serialization format (for instance catalog use pson, but certificates prefer raw encoding).

On the HTTP level, we correctly add the various encoding headers reflecting the serialization used.

You will find a [comprehensive list of all REST endpoint in puppet here](http://docs.puppetlabs.com/guides/rest_api.html)

### Puppet 2.7 indirection

The syntax I used in my samples are derived from the 2.6 puppet source. In Puppet 2.7, the dev team introduced (and are now contemplating removing) an `indirection` property in the model class which implements the indirector verbs (instead of being implemented directly in the model class).

This translates to:
``` ruby
  # 2.6 way, and possibly 2.8 onward
  Puppet::Node.find(...)
  
  # 2.7 way
  Puppet::Node.indirection.find(...)
```

## Gory details anyone?

OK, so how it works?

Let's focus on `Puppet::Node.find` call:

1. Ruby loads the [`Puppet::Node`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/node.rb) class
2. When mixing in [`Puppet::Indirector`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector.rb) we created a bunch of find/destroy... methods in the current model class
3. Ruby execute the `indirects` call from the `Puppet::Indirector` module
    1. This one creates a [`Puppet::Indirector::Indirection`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector/indirection.rb) stored locally in the `indirection` class instance variable
    2. This also registers the given indirection in a global indirection list
    3. This also register the given default terminus class. The terminus are loaded with a [`Puppet::Util::Autoloader`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/util/autoloader.rb) through a set of [`Puppet::Util::InstanceLoader`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/util/instance_loader.rb)
4. When this terminus class is loaded, since it somewhat inherits from [`Puppet::Indirector::Terminus`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector/terminus.rb), the `Puppet::Indirector:Terminus#inherited` ruby callback is executed. This one after doing a bunch of safety checks register the terminus class as a valid terminus for the loaded indirection.
5. We're now ready to really call `Puppet::Node.find`. `find` is one of the method that we got when we mixed-in [`Puppet::Indirector`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector.rb)
    1. `find` first create a [`Puppet::Indirector::Request`](https://github.com/puppetlabs/puppet/blob/2.6.x/lib/puppet/indirector/request.rb), with the given key.
    2. It then checks the terminus cache if one has been defined. If the cache terminus finds an instance, this one is returned
    3. Otherwise `find` delegates to the registered terminus, by calling `terminus.find(request)`
    4. If there's a result, this one is cached in the cache terminus
    5. and the result is returned

Pretty simple, isn't it?
And that's about the same mechanism for the three other verbs.

It is to be noted that the terminus are loaded with the puppet autoloader. That means it should be possible to add more indirection and/or terminus as long as paths are respected and they are in the `RUBYLIB`.
I don't think though that those paths are pluginsync'ed.

## Conclusion

I know that the indirector can be intimidating at first, but even without completely understanding the internals, it is quite easy to add a new terminus for a given indirection.

On the same subject, I highly recommends this presentation about [Extending Puppet](http://rcrowley.org/talks/sv-puppet-2011-01-11/) by Richard Crowley. This presentation also covers the _indirector_.

This article will certainly close the Puppet Extension Points series. The last remaining extension type (Faces) have already been covered thoroughly on the [Puppetlabs Docs site](http://puppetlabs.com/faces/).

The next article will I think cover the full picture of a full puppet agent/master run.


