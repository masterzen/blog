---

title: "Puppet Internals: the compiler"
date: 2012-03-17 19:34:54
comments: true
categories:
- puppet
tags:
- puppet
- compiler
- puppet internals
- ruby
---

And I'm now proud to present the second installation of my series of post about **Puppet Internals**:

Today we'll focus on the **compiler**.

# The Compiler

The compiler is at the heart of Puppet, master/agent or masterless. Its responsibility is to transform the AST into a set of resources called the _catalog_ that the agent can consume to perform the necessary changes on the node.

You can see the compiler as a function of the AST and Facts and returning the _catalog_.

The compiler lives in the ``lib/puppet/parser/compiler.rb`` file and more specifically in the ``Puppet::Parser::Compiler`` class. When a node connects to a master to ask for a catalog, [the Indirector](/2011/12/11/the-indirector-puppet-extensions-points-3/) directs the request to the compiler.

In a classic master/agent system, the agent does a REST _find catalog_ request to the master. The master catalog indirection is configured to delegate to the compiler. This happens in the ``lib/puppet/indirector/catalog/compiler.rb`` file. Check this [previous article about the Indirector](/2011/12/11/the-indirector-puppet-extensions-points-3/) if you want to know more.

The indirector request contains two things:

- what node we should compile
- the node's facts

## Produced Catalog

When we're talking about catalog, in the Puppet system it can mean two distinct things:

- a containment catalog
- a relationship resource catalog

The first one is the product of the compiler (which we'll delve into in this article). The second one is formed by the transformation of the first one in the agent. This is the later one that we usually call the **puppet catalog**.

Here is a simple manifest and the containment catalog that I obtained after compiling:
```ruby
class test {
  file {
    "/tmp/a": content => "test!"
  }
}

include test
```

And here is the produced catalog:

![Out of compiler containment catalog](/images/uploads/2012/03/containment-catalog.jpg "Puppet: containment catalog")

You'll notice that as its name implies, the containment catalog is a graph of classes and resources that follows the structure of the manifest.

## When Facts matter

In a master/agent system the facts are coming from the request in a serialized form. Those facts were created by calling _Facter_ on the remote node.

Once unserialized, the facts are cached locally as YAML (as per the default terminus for facts on a master). You can find them in the ``$vardir/yaml/facts/$certname.yaml`` file.

At the same time the compiler catalog terminus compute some server facts that are injected into the current node instance.

## Looking for the node

In Puppet there are several possibilities to store node definitions. They can be defined by ``node {}`` blocks in the ``site.pp``, by an _ENC_, into an LDAP directory, etc...

Before the compiler can start, it needs to create an instance of the ``Puppet::Node`` class, and fill this with the node informations. 

The node indirection terminus is controlled by the ``node_terminus`` puppet settings which by default is ``plain``. This terminus just creates a new empty instance of a ``Puppet::Node``.

In an _ENC_ setup, the terminus for the node indirection will be ``exec``. This terminus will create a ``Puppet::Node`` instance initialized with a set of classes and global parameters the compiler will be able to use.

The ``plain`` terminus for nodes calls ``Puppet::Node#fact_merge``. This methods _finds_ the current set of Facts of this node. In the ``plain`` case it involves reading the YAML facts we wrote to disk in the last chapter, and merging those to the current node instance parameters.

Back to the compiler catalog terminus, this one tries to find the node with the given request information and if not present by using the node ``certname``. Remember that the request to get a catalog from REST matches ``/catalog/node.domain.com``, in which case the request key is ``node.domain.com``.

## Let's compile

After that, we really enter the compiler code, when the compiler catalog terminus calls ``Puppet::Parser::Compiler.compile``, which creates a new ``Puppet::Parser::Compiler`` instance giving it our node instance.

When creating this compiler instance, the following is created:

- an empty catalog (an instance of ``Puppet::Resource::Catalog``). This one will hold the result of the compilation.
- a companion top scope (an instance of ``Puppet::Parser::Scope``)
- some other internal data structures helping the compilation

If the given node was coming from an _ENC_, the catalog is bootstrapped with the known node classes.

Once done, the ``compile`` method is called on the compiler instance. The first thing done is to bootstrap top scope with the node parameters (which contains the global data coming from the _ENC_ if one is used and the _facts_).

## Remember the AST

When we left the [Parser post](/2011/12/27/puppet-internals-the-parser/), we obtained an AST. This AST is a tree of ``AST`` instances that implement the guts of the Puppet language.

In this previous article we left aside 3 types of AST:

- Node AST
- Hostclass AST
- Definition AST

Those are different in the sense that we don't strictly evaluate them during compilation (more later on this step). No, those are _instantiated_ as part of the _initial import_ of the _known types_. If you're wondering why I spelled the Class AST as Hostclass, then it's because that's how it is spelled in the Puppet code; the reason being that ``class`` is a reserved word in Ruby :)

Using a lazy evaluation scheme, Puppet keeps (actually per environments), a list of all the parsed known types (classes, definitions and nodes that the parser encountered during parsing); this is called the _known types_. 

When this list is first accessed, if it doesn't exist, Puppet triggers the parser to populate it. This happens in ``Puppet::Node::Environment.known_resource_types`` which calls the ``import_ast`` method with the result of the parsing phase.

``import_ast`` adds to the _known types_ an instance of every definitions, hostclass, node returned by their respective ``instantiate`` method.

Let's have a closer look of the hostclass ``instantiate``:

```ruby
def instantiate(modname)
  new_class = Puppet::Resource::Type.new(:hostclass, @name)
  all_types = [new_class]
  code.each do |nested_ast_node|
    if nested_ast_node.respond_to? :instantiate
      all_types += nested_ast_node.instantiate(modname)
    end
  end
  return all_types
end
```

So ``instantiate`` returns an array of ``Puppet::Resource::Type`` of the given type. You'll notice that the hostclass code above analyzes its current class AST children for other 'instantiable' AST elements that will also end in the _known types_.

## Known Types

The _known types_ I'm talking about since a while all live in the ``Puppet::Resource::TypeCollection`` object. There's one per Puppet environment in fact.

This object main responsibility is storing all known classes, nodes and definitions to be easily accessed by the compiler. It also watches all loaded files by the parser, so that it can trigger a re-parse when one of those is updated. It also serves as the Puppet class/module autoloader (when asking it for an unknown class, it will first try to load it from disk and parse it).

## Scopes

Let's open a parenthesis to explain a little bit what the scope is. The scope is an instance of ``Puppet::Parser::Scope`` and is simply a symbol table (as explained in the [Dragon Book](http://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools)). It just keeps the values of Puppet variables.

It forms a tree, with the top scope (the one we saw the creation earlier) being the root of all scopes. This tree contains one child per new namespace.

The scope supports two operations:

1. Looking up a variable value
1. Setting a variable value

Look up is done with the ``lookupvar`` method. If the variable is qualified it will directly ask the correct scope for its value. For instance ``::$hostname`` will fetch directly the top scope fact ``hostname``.

Otherwise it will either return its value in the local scope if it exists or delegate to the parent scope. This can happen up until the top scope. If the value can't be found anywhere, the ``:undef`` ruby symbol will be returned.

Note that this dynamic scope behavior will be removed in the next Puppet version, where only the local scope and the top scope will be supported. More information is available in this [Scope and Puppet article](http://docs.puppetlabs.com/guides/scope_and_puppet.html).

Setting a variable is done with the ``setvar`` method. This method is called for instance by the AST class responsible of variable assignment (the ``AST::VarDef``).

Along with regular variables, each scope has the notion of _ephemeral scope_. An _ephemeral scope_ is a special transient scope that stores only regex capture ``$0`` to ``$xy`` variables. 

Each scope level maintains a stack of _ephemeral scopes_, which is by default empty.

In Puppet there is no scopes for other language structures than classes (and nodes and definitions), so inside the following ``if``, an ephemeral scope is created, and pushed on the stack, to store the result of the regex match:

```ruby
if $var =~ /test(.*)/ {
  # here $0, $1... are available
}
```

When Puppet execution reaches the closing '}', the _ephemeral scope_ is popped from the _ephemeral scope_ stack, removing the ``$0`` definition.

``lookupvar`` will also ask the _ephemeral scope_ stack if needed.

Orthogonally, the scope instance will also store resource defaults.

## Talking about AST Evaluation

And here we need to take a break from compilation to talk about AST evaluation, which I elegantly eluded from the previous post on the Parser.

Every AST node (both branch and leaf ones) implements the ``evaluate`` method. This method takes a ``Puppet::Parser::Scope`` instance as parameter. This is the scope instance that is valid at the moment we evaluate this AST node (usually the scope associated with the class where the code we evaluate is).

There are several outcomes possible after evaluation:

- Manipulation of the scope (like variable assignment, variable lookup, parser function call)
- Evaluation of AST children of this node (for instance ``if``, ``case``, selectors need to evaluate code in one their children branch)
- Creation of ``Puppet::Parser::Resource`` when encountering a puppet resource
- Creation of ``Puppet::Resource::Type`` (more puppet classes)

When an AST node evaluates its children it does so by calling ``safeevaluate`` on them which in turn will call ``evaluate``. Safeevaluate will shield the caller from exceptions, and transform them to parse errors that can specify the line and file of the puppet instruction that triggered the problem.

## Shouldn't we talk about compilation?

Let's go back to the compiler now. We left the compiler after we populated the _top scope_ with the node's facts, and we still didn't properly started the compilation phase itself.

Here is what happens after:

1. Main class evaluation
1. Node AST evaluation
1. Evaluation of the node classes if any
1. Recursive evaluation of definitions and collections (called generators)
1. Evaluation of relationships
1. Resource overrides evaluation
1. Resource finish
1. Ship the catalog

After that, what remains is the containment catalog. This one will be transformed to a _resource_ containment catalog. We call _resource catalog_ an instance of ``Puppet::Resource::Catalog`` where all ``Puppet::Parser::Resource`` have been transformed to ``Puppet::Resource`` instances.

Let's now see in order the list of operations we outlined above and that form the compilation.

### Main class evaluation

The main class is an hidden class where every code outside any definition, node or class ends. It's a kind of top class from which any other class is inner. This class is special because it has an _empty name_.

Evaluating the main class means:

1. Creating a companion resource (an instance of ``Puppet::Parser::Resource``) whose scope is the _top scope_.
1. Add this resource to the catalog
1. Evaluating the class code of this resource

Let's focus on this last step which happens in ``Puppet::Parser::Resource.evaluate``.
It involves mainly getting access to the ``Puppet::Resource::Type`` instance matching our class (its type in fact) from the _known types_, and then calling the ``Puppet::Resource::Type.evaluate_code`` method.

#### Evaluating code of a class

I'm putting aside the main class evaluation to talk a little bit about code evaluation of a given class because that's something we'll see for every class or node during compilation.

This happens during ``Puppet::Resource::Type.evaluate_code`` which essentially does:

1. Create a scope for this class (unless we're compiling the main class which already uses the _top scope_)
1. Ask the class AST children to evaluate with this scope

We saw in the [Puppet Parser post](/2011/12/27/puppet-internals-the-parser/) how the AST was produced. Eventually some of those AST nodes will end up in the ``code`` element of a given puppet class (you can refer to the Puppet grammar and ``Puppet::Parser::AST::Hostclass`` for the code), under the form of an ``ASTArray`` (which is an array of AST nodes).

### Node Evaluation

As for the main class, the current node compilation phase:

- ask the _known types_ about the current node, and if none are found ask for a _default_ node.
- creates a resource for this node, add it to the catalog
- evaluates this node resource

This last evaluation will execute the given node AST code.

### Node class evaluation

If the node was provided by an ENC, the compiler will then evaluate those classes. This is the same process as for the main class, where for every classes we create a resource, add it to the catalog and then evaluate it.

### Evaluation of Generators

In Puppet the generators are the entities that are able to spawn new resources:

- collections, including storeconfig exported resources
- definitions

This part of the compilation loops calling ``evaluate_definitions`` and ``evaluate_collections``, until none of those produces new resources.

#### Definitions

During the AST code evaluation, if the compiler encounters a definition call, the ``Puppet::Parser::AST::Resource.evaluate`` will be called (like for every resource).

Since this resource comes from a definition, a type resource will be instantiated and added to the catalog. This resource will not be evaluated at this stage.

Later, when ``evaluate_definitions`` is called, it will pick up any resource that hasn't been evaluated (which is the case of our definition resources) and evaluates them.

This operation might in turn create more unevaluated resources (ie new definition spawning more definition resources), which will be evaluated in a subsequent pass over ``evaluate_definitions``.

#### Collections

When the parser parses a collection which are defined like this in the Puppet language:

```ruby
File <<| tag == 'key' |>>
```

it creates an AST node of type ``Puppet::Parser::AST::Collection``. The same happen if you use the ``realize`` function.

Later when the compiler evaluate code and encounters this collection instance, it will create a ``Puppet::Parser::Collector`` and register it to the compiler.

Even later, during ``evaluate_collections``, the ``evaluate`` method of all the registered collectors will be called. This method will either fetch exported resources from storeconfigs or virtual resources, and create ``Puppet::Parser::Resource`` that are registered to the compiler. 

If the collector has created all its resources, it is removed from the compiler.

### Relationship evaluation

The current compiler holds the list of relationships defined with the ``->`` class of relationship operators (but not the ones defined with the ``require`` or ``before`` meta-parameters).

During code evaluation, when the compiler encounters the relationship AST node (an instance of ``Puppet::Parser::AST::Relationship``), it will register a ``Puppet::Parser::Relationship`` instance to the compiler.

During the ``evaluate_relationships`` method of the compiler, every registered relationship will be evaluated. This evaluation simply adds the destination resource reference to the source resource meta-parameter matching the operator.

### Resource overrides

And the next compilation phase consists in adding all the overrides we discovered during the AST code evaluation. Normally overrides are applied as soon as they are discovered, but it can happen than an override (especially for collection overrides), can not be applied because the resources it should apply on are not yet created.

Applying an override consist in setting a given resource parameter to the overridden value.

### Resource finishing

During this phase, the compiler will call the ``finish`` method on every created resources.
This methods is responsible of:

- adding resource defaults to the resource parameters
- tagging the resource with the current scope tags
- checking that resource parameter are valid

### Resource meta-parameters

The next step in the compilation process is to set all meta-parameter of our created resources, starting from the main class and walking the catalog from there. 

### Finish

Once everything has been done, the compiler runs some checks to make sure all overrides and collections have been evaluated.
Then the catalog is transformed to a ``Puppet::Resource`` catalog (which doesn't change its layout, just the instance of its vertices).

# Conclusion

I hope you now have a better view of the compilation process. As you've seen the compilation is a complex process, which is one of the reason it can take some time. But that's the price to pay to produce a data only graph tailored to one host that can be applied on the host.

Stay tuned here for the next episode of my Puppet Internals series of post. The next installment will certainly cover the Puppet transaction system, whose role is to apply the catalog on the agent.

