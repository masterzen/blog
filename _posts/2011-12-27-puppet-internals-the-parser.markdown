---

title: "Puppet Internals: the parser"
date: 2011-12-27 16:46:51
comments: true
category:
- Puppet
tags:
- puppet
- puppet internals
- parser
- ruby
---

As more or less promised in my series of post about [Puppet Extension Points](/2011/11/02/puppet-extension-point-part-2/), here is the first post about **Puppet Internals**.

The idea is to produce a series of blog post about each one about a Puppet sub-system.

Before starting, I first want to present what are the various sub-blocks that forms Puppet, or Puppet: the Big Picture:

![Puppet the Big Picture](/images/uploads/2011/12/big-picture.jpg "Puppet: the Big Picture")

I hope to be able to cover each of those sub-blocks in various posts, but we'll today focus on the **Puppet Parser**.


# The Puppet Parser

The Puppet Parser responsibility is to transform the _textual manifests_ into a computer usable data structure that could be fed to the compiler to produce the _catalog_. This data structure is called an [AST (Abstract Syntax Tree)](http://en.wikipedia.org/wiki/Abstract_syntax_tree).

The Puppet Parser is the combination of various different sub-systems:

- the lexer
- the racc-based parser
- the AST model

## The Lexer

The purpose of the _lexer_ is to read manifests characters by characters and to produce a _stream of tokens_. A token is just a symbol (combined with data) that represents a valid part of the Puppet language.

For instance, the _lexer_ is able to find things such (but not limited to):

- reserved keywords (like case, class, define...)
- quoted strings
- identifiers
- variables
- various operators (like left parenthesis or right curly braces...)
- regexes
- ...

Let's take an example and follow what comes out of the _lexer_ when scanning this manifest:

```ruby
$variable = "this is a string"
```

And here is the stream of tokens that is the outcome of the _lexer_:

```
:VARIABLE(VARIABLE) {:line=>1, :value=>"variable"}
:EQUALS(EQUALS) {:line=>1, :value=>"="}
:STRING(STRING) {:line=>1, :value=>"this is a string"}
```

As you can see, a puppet token is the combination of a symbol and a hash.

Let's see how we achieved this result. First you must know that the Puppet _lexer_ is a regex-based system.
Each token is defined as a regex (or a stock string). When reading a character, the _lexer_ 'just' checks if one of the string or regex can match. If there is one match, the lexer emits the corresponding token.

Let's take our example manifest (the variable assignment above), and see what happens in the lexer:

1. read $ character
1. no regex match, let's read some more characters
1. read 'variable', still no match, our current buffer contains ``$variable``
1. read ' ', oh we have a match against the DOLLAR_VARIABLE token regex
1. this token is special, it is defined with a ruby block. When one of those token is read and matched, the block is executed.
1. the block just emits the ``VARIABLE("variable")`` token

The _lexer_'s scanner doesn't try every regexes or strings, it does this in a particular order. In short it tries to maximize the length of the matched string, in a word the lexer is greedy. This helps removing ambiguity.

As seen in the token stream above, the _lexer_ associates to each token an hash containing the line number where we found it. This allows error messages in case of parsing error to point to the correct line. It also helps _puppetdoc_ to associate the right comment with the right language structure.

The _lexer_ also supports lexing contexts. Some tokens are valid in some specific contexts only, this is true especially when parsing quoted strings for variables interpolation.

Not all lexed tokens emit tokens for the parser. For instance comments are scanned (and stored in a stack for _puppetdoc_ use), but they don't produce a token for the parser: they're skipped.

Finally, the lexer also maintains a stack of the class names it crossed. This is to be able to find the correct fully qualified name of inner classes as seen in the following example:

```ruby
class outer {
  class middle {
    class inner {
      # we're in outer::middle::inner
    }
  }
}
```

If you want more information about the lexer, check the [Puppet::Parser::Lexer](https://github.com/puppetlabs/puppet/blob/master/lib/puppet/parser/lexer.rb) class.


## The parser

The _parser_ is based on [racc](http://raa.ruby-lang.org/project/racc/). Racc is a ruby port of the good old [Yacc](http://en.wikipedia.org/wiki/Yacc). Racc, like Yacc, is what we call a [LALR parser](http://en.wikipedia.org/wiki/LALR_parser).

The 'cc' in Racc means 'compiler of compiler'. It means in fact that the parser is generated from what we call a _grammar_ (and for LALR parsers, even a _context free grammar_). The generated parser is table driven and consumes tokens one by one. Those kind of parsers are sometimes called Shift/Reduce parsers. 

This grammar is written in a language that is a machine readable version of a [Backus-Naur Form or "BNF"](http://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form).

There are different subclasses of _context free grammars_. Racc works best with LR(1) grammars, which means it must be possible to parse any portion of an input string with just a single token lookahead. Parsers for LR(1) grammars are deterministic. This means that we only need a fixed number of lookahead tokens (in our case 1) and what we already parsed to find what next rule to apply.

Roughly it does the following:

1. read a token
1. shift (this mean put the token on the stack), goto 1. until we can reduce
1. reduce the read tokens with a grammar rules (this involves looking ahead)

We'll have a deeper look in the subsequent chapters. Meanwhile if you want to learn everything about LALR Parsers or parsers in general, I highly recommend the [Dragon Book](http://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools)

### The Puppet Grammar

The Puppet Grammar can be found in ``lib/puppet/parser/grammar.ra`` in the sources.
It is a typical racc/yacc grammar that

- defines the known tokens (those matches the lexed token names)
- defines the precedence of operators
- various recursive rules that form the definition of the Puppet languages

Let's have a look to a bit of the Puppet Grammar to better understand how it works:

```ruby
statement_or_declaration:    resource
  | collection
  | assignment
  | casestatement
  | ifstatement_begin
...
assignment:     VARIABLE EQUALS expression {
  variable = ast AST::Name, :value => val[0][:value], :line => val[0][:line]
  result = ast AST::VarDef, :name => variable, :value => val[2], :line => val[0][:line]
}
...
expression:   rvalue
  | hash
  ...

rvalue:       quotedtext
  | name
  ...

quotedtext: STRING  { result = ast AST::String, :value => val[0][:value], :line => val[0][:line] }
```

So the closer look above shows 4 rules:

- a non-terminal rule called ``statement_or_declaration`` which is an alternation of sub-rules
- a terminal rule called ``assignment``, with a ruby code block that will be executed when this rule will be reduced.
- a non terminal rule called ``expression``
- a terminal rule ``quotedtext`` with a ruby block

To understand what that means, we could translate those rules by:

1. A statement or declaration can be either a ``resource`` or a ``collection``, or an ``assignement``
1. An ``assignment`` is when the parser finds a ``VARIABLE`` token followed by an ``EQUALS`` token and an ``expression``
1. An ``expression`` can be a ``rvalue`` or an ``hash`` (all defined later on in the grammar file)
1. A ``rvalue`` can be among other things a ``quotedtext``
1. And finally a ``quotedtext`` can be ``STRING`` (among other things)

You can generate yourself the puppet parser by using racc, it's as simple as:

1. Installing racc (available as a gem)
1. running: ``make -C lib/puppet/parser``

This rebuilds the ``lib/puppet/parser/parser.rb`` file.

You can generate a debug parser that prints everything it does if you use ``-g`` command-line switch to racc (check the ``lib/puppet/parser/makefile`` and define ``@@yydebug = true`` in the parser class.

The parser itself is controlled by the ``Puppet::Parser::Parser`` class which is in ``lib/puppet/parser/parser_support.rb``. This class is requiring the generated parser (both share the same ruby class). That means that the ruby blocks in the grammar will be executed in the context of an instance of the ``Puppet::Parser::Parser`` class. In other words, you can call from the grammar, methods defined in the ``parser_support.rb`` file. That's the reason we refer to the ``ast`` method in the above example. This method just creates an instance of the given class and associates some context to it.

Let's go back a little bit to the reduce operation. When the parser is reducing, it pops from the stack the reduced tokens and pushes the result to the stack. The result can either be what ends in the ``result`` field of the grammar ruby block or the result of the reduction of the mentioned rule (when it's a non-terminal one).

In the ruby block of a terminal rule, it is possible to access the tokens and rule results currently parsed in the ``val`` array. To get back to the assignment statement above, ``val[0]`` is the ``VARIABLE`` token, and ``val[2]`` the result of the reduction of the ``expression`` rule.

### The AST

The AST is the computer model of the parsed manifests. It forms a tree of instances of the AST base class. There are AST classes (all inheriting the AST base class) for every elements of the language. For instance there's one for puppet _classes_, for _if_, _case_ and so on. You'll find all those in ``lib/puppet/parser/ast/`` directory.

There are two kinds of AST classes:

- leaves: which represent some kind of values (like an identifier or a string)
- branches: which encompass more than one other AST classes (like if, case or class). This is what forms the tree.

All AST classes implement the ``evaluate`` method which we'll cover in the compiler article.

For instance when parsing an if/else statement like this:

```ruby
if $var {
  notice("var is true")
} else {
  notice("var is false")
}
```

The whole if/else once parsed will be an instance of ``Puppet::Parser::AST::IfStatement`` (which can be found in ``lib/puppet/parser/ast/ifstatement.rb``. 

This class defines three instance variables:

1. ``@test``
1. ``@statements``
1. ``@else``

The grammar rule for ifstatement is (I simplified it for the purpose of the article):

```ruby
ifstatement:  IF expression LBRACE statements RBRACE else {
  args = {
    :test => val[0],
    :statements => val[2],
    :else = val[4]
  }
  result = ast AST::IfStatement, args
}
```

Notice how the ``AST::IfStatement`` is initialized with the args hash containing the ``test``,``statements`` and ``else`` result of the those rules. Those rules ``result`` will also be AST classes, and will end up in the IFStatement fields we talked about earlier.

Thus this forms a tree. If you look to the ``AST::IfStatement#evaluate`` implementation you'll see that depending on the result of the evaluation of the ``@test`` it will either evaluate ``@statements`` or ``@else``.

Calling the ``evaluate`` method of the root element of this tree will in chain trigger calling ``evaluate`` on children like for the IfStatement example. This process will be explained in details in the compiler article, but that's essentially how Puppet compiler works.

### An Example Step by Step

Let's see an end-to-end example of parsing a simple manifest:

```ruby
class test {
  file {
    "/tmp/a": content => "test!"
  }
}
```

This will produce the following stream of tokens:

```
:CLASS(CLASS) {:line=>1, :value=>"class"}
:NAME(NAME) {:line=>1, :value=>"test"}
:LBRACE(LBRACE) {:line=>1, :value=>"{"}
:NAME(NAME) {:line=>2, :value=>"file"}
:LBRACE(LBRACE) {:line=>2, :value=>"{"}
:STRING(STRING) {:line=>3, :value=>"/tmp/a"}
:COLON(COLON) {:line=>3, :value=>":"}
:NAME(NAME) {:line=>3, :value=>"content"}
:FARROW(FARROW) {:line=>3, :value=>"=>"}
:STRING(STRING) {:line=>3, :value=>"test!"}
:RBRACE(RBRACE) {:line=>4, :value=>"}"}
:RBRACE(RBRACE) {:line=>5, :value=>"}"}
```

And now let's dive in the parser events (I simplified the outcome because the Puppet grammar is a little bit more complex
than necessary for this article). The following example shows all actions of the Parser and how looks the parser stack after the operation took place. I elided some of the stacks when not strictly needed to understand what happened.

1. _receive_: ``CLASS`` _(our parser got the first token from the lexer)_
1. _shift_ ``CLASS`` _(there's nothing else to do for the moment)_
   
   the result of the shift is that we now have one token in the parser stack
   
   stack: ``[ CLASS ]``

1. _receive_: ``NAME("test")`` _(we get one more token)_
1. _shift_ ``NAME`` _(still no rules can match so we shift it)_

   stack: ``[ CLASS NAME("test") ]``

1. _reduce_  ``NAME`` --> ``classname`` _(oh and now we can reduce a rule)_

   notice how the stacks now contains a classname and not a NAME
   
   stack: ``[ CLASS (classname "test") ]``

1. _receive_: ``LBRACE``
1. _shift_ ``LBRACE``

   stack: ``[ CLASS (classname "test") LBRACE ]``

1. _receive_: ``NAME("file")``
1. _shift_ ``NAME``

   stack: ``[ CLASS (classname "test") LBRACE NAME("file") ]``

1. _receive_: ``LBRACE``
1. _reduce_ ``NAME`` --> ``classname``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") ]``

1. _shift_: ``LBRACE``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE ]``

1. _receive_ ``STRING("/tmp/a")``
1. _shift_ ``STRING``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE STRING("/tmp/a") ]``

1. _reduce_ ``STRING`` --> ``quotedtext``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (quotedtext AST::String("/tmp/a")) ]``

1. _receive_ ``COLON``
1. _reduce_ ``quotedtext`` --> ``resourcename``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resourcename  AST::String("/tmp/a")) ]``

1. _shift_ ``COLON``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resourcename  AST::String("/tmp/a")) COLON ]``

1. _receive_: ``NAME("content")``
1. _shift_ ``NAME``
   
   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resourcename  AST::String("/tmp/a")) COLON NAME("content") ]``

1. _receive_: ``FARROW``
1. _shift_ ``FARROW``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resourcename  AST::String("/tmp/a")) COLON NAME("content") FARROW ]``

1. _receive_: ``STRING("test!")``
1. _shift_: ``STRING``
1. _reduce_ ``STRING`` --> ``quotedtext``
1. _receive_: ``RBRACE``
1. _reduce_  ``quotedtext`` --> ``rvalue``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resourcename  AST::String("/tmp/a")) COLON NAME("content") FARROW (rvalue AST::String("test!"))]``

1. _reduce_ ``rvalue`` --> ``expression``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resourcename  AST::String("/tmp/a")) COLON NAME("content") FARROW (expression AST::String("test!"))]``

1. _reduce_  ``NAME FARROW expression`` --> ``param``  _(we've now a resource parameter)_

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resourcename  AST::String("/tmp/a")) COLON (param AST::ResourceParam("content"=>"test!")))]``

1. _reduce_ ``param`` --> ``params`` _(multiple parameters can form a params)_
1. _reduce_ ``resourcename COLON params`` --> ``resourceinst`` _(name: parameters form a resouce)_

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resourceinst (AST::ResourceInstance(...)))]``

1. _reduce_  ``resourceinst`` --> ``resourceinstances`` _(more than one resourceinst can form resourceinstances)_

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resourceinstances [(resourceinst (AST::ResourceInstance(...)))] )]``

1. _shift_ ``RBRACE``
1. _reduce_  ``classname LBRACE resourceinstances RBRACE`` --> ``resource`` _(we've discovered a resource)_

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resource AST::Resource(...))]``

1. _receive_: ``RBRACE``
1. _reduce_  ``resource`` --> ``statement_or_declaration`` _(a resource is one statement)_
1. _reduce_  ``statement_or_declaration`` --> ``statement_and_declarations``
1. _shift_ ``RBRACE``

   stack: ``[ CLASS (classname "test") LBRACE (classname "file") LBRACE (resource AST::Resource(...)) RBRACE ]``

1. _reduce_ ``CLASS classname LBRACE statements_and_declarations RBRACE`` --> ``hostclass`` _(we've discovered a puppet class)_

   stack: ``[ (hostclass AST::Hostclass(...)) ]``

1. _reduce_  ``hostclass`` --> ``statement_or_declaration``
1. _reduce_  ``statement_or_declaration`` --> ``statements_and_declarations``
1. _receive_: _end of file_
1. _reduce_  ``statements_and_declarations`` --> ``program``
1. _shift_ _end of file_

   stack: ``[ (program (AST::ASTArray [AST::Hostclass(...))])) ]``

And the parsing is now over. What is returned is this ``program``, which is in fact an instance of an ``AST::ASTArray``.

If we now analyze the produced AST, we find:

- ``AST::ASTarray`` - _array of AST instances, this is our program_
  - ``AST::Hostclass`` - _an instance of a class_
    - ``AST::Resource`` - _contains an array of resource instances_ 
      - ``AST::ResourceInstance``
        - ``AST::ResourceParam`` - _contains the "content" parameter_
          - ``AST::String("content")``
          - ``AST::String("test!")``


What's important to understand is that the AST depends only from the manifests. Thus the Puppet master needs only to reparse manifests only if they change. 

## What's next?

The next episode will follow-up after the Parser: the compilation. The Puppet compiler takes the AST, injects into it the facts and gets what we call a catalog; that's exactly what we'll learn in the next article (sorry, no ETA yet).

Do not hesitate to comment or ask questions on this article with the comment system below :)

And happy new year all!
