---

title: In love with zsh, part 1
date: 2009-04-19 20:03:55 +02:00
comments: true
wordpress_id: 26
wordpress_url: http://www.masterzen.fr/?p=26
category:
- System Administration
- zsh
tags:
- linux
- zsh
- unix
- shell
---
**Note**: when I started writing this post, I didn't know it would be this long.
I decided then to split it in several posts, each one covering one or more interesting aspect of zsh.
You're now reading _part 1_.

I first used a [Unix](http://en.wikipedia.org/wiki/Unix) computer in 1992 (it was running [SunOS 4.1](http://en.wikipedia.org/wiki/SunOS) if I remember correctly).
I'm using [Linux](http://www.kernel.org/) since 1999 (after using [VMS](http://en.wikipedia.org/wiki/OpenVMS) throughout the 90s in school, but I left the Unix world while I was working with RAYflect doing 3D stuff on Mac and Windows).

During the time I worked with those various unices (including [Irix](http://en.wikipedia.org/wiki/Irix) on a [Crimson](http://www.futuretech.blinkenlights.nl/crimson.html)), I think I've used almost every possible shell with various level of pleasure and expertise, including but not limited to:

- [tcsh](http://en.wikipedia.org/wiki/Tcsh)
- [ksh](http://en.wikipedia.org/wiki/Korn_shell)
- [bash](http://en.wikipedia.org/wiki/Bash)
- [zsh](http://en.wikipedia.org/wiki/Zsh)


When my own road crossed ZSH (about 6 years ago), I felt in love with this powerful shell, and it's now my default shell on my servers, workstations and of course my macbook laptop.

The point of this blog post is to give you an incentive to switch from _insert random shell_ here to **zsh** and never turn back.

The whole issue with **zsh** is that the usual random Linux distribution ships with Bash by default (that's not really, true as [GRML](http://grml.org/) ships with zsh, and a good configuration). And Bash does its job well enough and is wide-spread, that people have usually only low incentive to switch to something different. I'll try to let you see why **zsh** is worth the little investment.
## Which version should I run?

Right now, zsh exists in 2 versions a stable one (4.2.7) and a development one (4.3.9).
I'm of course running the development version (I usually prefer seeing new bugs than old bugs :-))

I recommend using the development version.
## UTF-8 support, anyone?

Some people don't want to switch to zsh because they think zsh doesn't support UTF-8. That's plain wrong, if you follow my previous advice which is to run a version greater than 4.3.6, UTF-8 support is there and works really fine.
## Completion

One of the best thing in zsh is the _TAB completion_. It's certainly the best _TAB completion_ I could use in every shell I tried. It can completes almost anything, from _files_ (of course), to _users_, including but not limited to _hosts_, _command options_, _package names_, _git revisions/branches_ etc.

**Zsh** ships with completions for almost every shipped apps on earth. And the beauty is that completion is so much configurable that you can twist it to your own specific taste.

To activate completion on your setup:
``` sh

% zmodload zsh/complist
% autoload -U compinit && compinit

```

The completion system is completely configurable. To configure it we use the zstyle command:
``` sh

  zstyle <context> <styles>

```
</styles></context>
How does it work?

The context defines where the style will apply. The context is a string of ':' separated strings:
':completion:function:completer:command:argument:tag'
Some part can be replaced by *, so that ':completion:*' is the least specific context.
More specific context wins over less specific ones of course.

The various styles selects the options to activate (see below).

If you want to learn more about zsh completion, please [read the zsh section completion manual](http://zsh.sourceforge.net/Doc/Release/zsh_19.html).

Zsh completion is also:
### Formatting completion

When zsh needs to display completion matches or errors, it uses the format style for doing so.
``` sh

  zstyle ':completion:*' format 'Ouch: %d :-)'

```

%d will be replaced by the actual text zsh would have been printed if no format style were applied.
You can use the same escape sequences as in zsh prompts.

Since there are many different types of messages, it is possible to restrict to warnings or messages by changing
the _tags_ part of the context:
``` sh

  zstyle ':completion:*:warnings' format 'Too bad there is nothing'

```

### ![](/images/uploads/2009/04/format-warnings.jpg "format-warnings")

And since it is possible to use all the prompt escapes, you can add style to the formats:
``` sh

# format all messages not formatted in bold prefixed with ----
zstyle ':completion:*' format '%B---- %d%b'
# format descriptions (notice the vt100 escapes)
zstyle ':completion:*:descriptions'    format $'%{\e[0;31m%}completing %B%d%b%{\e[0m%}'
# bold and underline normal messages
zstyle ':completion:*:messages' format '%B%U---- %d%u%b'
# format in bold red error messages
zstyle ':completion:*:warnings' format "%B$fg[red]%}---- no match for: $fg[white]%d%b"

```

And the result:
### Grouping completion

By default matches comes in no specific order (or in the order they've been found).
It is possible to separate the matches in distinct related groups:
``` sh

  # let's use the tag name as group name
  zstyle ':completion:*' group-name ''

```

An example of groups:
[![Grouping matches](/images/uploads/2009/04/group-name-300x130.jpg "group-name")](/images/uploads/2009/04/group-name.jpg)
### Menu completion

Menu completion is when you press TAB several times and the completion changes to cycle through the available matches. By default in zsh, menu completion activates the second time you press the TAB key (the first one triggered the first completion).
### Menu selection

Menu selection is when zsh displays below your prompt the list of possible selections arranged by categories.

A short drawing is always better than thousands words, so hop an example:

[![Menu Selection - here I\'m cycling through gzip options](/images/uploads/2009/04/menu-selection.jpg "menu-selection")](/images/uploads/2009/04/menu-selection.jpg)


In this example I typed gzip -&lt;TAB&gt; then navigated with the arrows to --stdout.

To activate menu selection:
``` sh

  # activate menu selection
  zstyle ':completion:*' menu select

```

### There's also approximate completion

With this, zsh corrects what you already have typed.
Approximate completion is controlled by the
```
_approximate
```
completer.
Approximate completion looks first for matches that differs by one error (configurable) to what you typed.
An error can be either a transposed character, a missing character or an additional character.
If some corrected entries are found they are added as matches, if none are found, the system continues with 2 errors and so on.
Of course, you want it to stop at some level (use the max-errors completion style).
``` sh

  # activate approximate completion, but only after regular completion (_complete)
  zstyle ':completion:::::' completer _complete _approximate
  # limit to 2 errors
  zstyle ':completion:*:approximate:*' max-errors 2
  # or to have a better heuristic, by allowing one error per 3 character typed
  # zstyle ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'

```

### Completion of about everything

From X windows, to hosts from users, almost everything including shell variables can be completed or menu-selected.

Here I typed "echo $PA&lt;TAB&gt;" and navigated to PATH:

![Variable Completion](/images/uploads/2009/04/var-completion.jpg "var-completion")

Now, one thing that is extremely useful is completion of hosts:
``` sh

# let's complete known hosts and hosts from ssh's known_hosts file
basehost="host1.example.com host2.example.com"
hosts=($((
( [ -r .ssh/known_hosts ] && awk '{print $1}' .ssh/known_hosts | tr , '\n');\
echo $basehost; ) | sort -u) )

zstyle ':completion:*' hosts $hosts

```

## Aliases

Yeah, I see, you're wondering, aliases, pffuuuh, every shell on earth has aliases.

Yes, but does your average shell has global or suffix aliases?
### Suffix Aliases

Suffix aliases are aliases that matches the end of the command-line.

Ex:
``` sh

% alias -s php=nano

```

Now, I just have to write:
``` sh

% index.php

```

And zsh executes nano index.php. Clever isn't it?
### Global Aliases

Global aliases are aliases that match anywhere in the command line.

Typical uses are:
``` sh

  % alias -g G='| grep'
  % alias -g WC='| wc -l'
  % alias -g TF='| tail -f'
  % alias -g DN='/dev/null'

```

Now, you just have to issue:
``` sh

% ps auxgww G firefox

```

to find all firefox processes. Still not convinced?
### Too risky?

Some might argue that global aliases are risky because zsh can change your command line behind your back if you need to have let's say a capital G in there.

Because of this I'm using the GRML way: I use a special key combination (see in an upcoming post about key binding) that auto-completes my aliases directly on the command line, without defining a global alias.
## Globbing

One of the best feature, albeit one of the more difficult to master is zsh extended globing.

Globbing is the process of matching several files or paths with an expression. The most usually known forms are * or ?, like: *.c to match every file ending with .c.

Zsh pushes the envelop far away, supporting the following:

Let's say our current directory contains:
```
  test.c
  test.h
  test.1
  test.2
  test.3
  a/a.txt
  b/1/b.txt
  b/2/d.txt
  team.txt
  term.txt
```
### Wildcard: *

This is the well known wildcard. It matches any amount of characters.
As in:
``` sh

% echo *.c
test.c

```

### Wildcard: ?

This matches only one character.
As in:
``` sh

% echo test.?
test.c test.h

```

### Character classes: [...]

This is a character class. It matches any character listed between the braces.
The content can be either single characters:
<blockquote>[abc0123] will match either a,b,c,0,1,2,3</blockquote>
or range of characters:
<blockquote>[a-e] will match from a to e inclusive</blockquote>
or POSIX character classes
<blockquote>[[:space:]] will match only spaces (refer to zshexpn(1) for more information)</blockquote>
The character classes can be negated by a leading ^:
<blockquote>[^abcd] matches only character outside of a,b,c,d</blockquote>
If you need to list - or ], it should be the first character of the class. If you need both list ] first.

Example:
``` sh

% echo test.[ch]
test.c test.h

```

### Number ranges &lt;x-y&gt;

x and/or y can be omitted to have an open-ended range.
&lt;-&gt; match all numbers.
``` sh

% echo test.<0-10>
test.1 test.2 test.3

```

``` sh

% echo test.<2->
test.2 test.3

```

### Recursive matching: **

You know find(1), but did you know you can do almost everything you need with only zsh?
``` sh

% echo **/*.txt
a/a.txt b/1/b.txt b/2/d.txt

```

### Alternatives: (a|b)

Matches either _a_ or _b_. _a_ and _b_ can be any globbing expressions of course.
``` sh

% echo test.(1|2)
test.1 test.2
% echo test.(c|<1-2>)
test.1 test.2 test.c

```

### Negated matches ^ (only with extended globbing)

There are two possibilities:
<blockquote>leading ^: as in ^*.o which selects every file except those ending with .o</blockquote>
<blockquote>pattern1^pattern2: pattern1 will be matched as a prefix, then anything not matching pattern2 will be selected</blockquote>
``` sh

% ls te*
test.c test.h team.txt term.txt
% echo te^st.*
team.txt term.txt

```

If you use the negation in the middle of a path section, the negation only applies to this path part:
``` sh

% ls /usr/^bin/B*
/usr/lib/BuildFilter  /usr/sbin/BootCacheControl

```

### Pattern exceptions (~)

Pattern exceptions are a way to express: "match this pattern, but not this one".
``` sh

# let's match all files except .svn dirs
% print -l **/*~*/.svn/* | grep ".svn"
# an nothing prints out, so that worked

```

It is to be noted that * after the ~ matches a path, not a single directory like the regular wildcard.
### Globbing qualifiers

zsh allows to further restrict matches on file meta-data and not only file name, with the globbing qualifiers.

The globbing qualifier is placed in () after the expression:
``` sh

# match a regular file with (.)
% print -l *(.)

```

We can restrict by:

- **(.)**: regular files
- **(/)**: directories
- **(*)**: executables
- **(@)**: symbolic links
- **(R),(W),(X),(U)**: file permissions
- **(LX),(L+X),(L-X),(LmX)**: file size, with X in bytes, + for larger than files, - for smaller than files, m
can be modifier for size (k for KiB, m for MiB)
- **(mX),(m+X),(m-X)**: matches file modified "more than X days ago". A modifier can be used to express X in hours (h), months (M), wweks (W)...
- **(u{owner})**: a specific file _owner_
- **(f{permission string ala chmod})**: a specific file _permissions_


``` sh

% ls -al
total 0
drwxr-xr-x  8 brice wheel 272 2009-04-14 18:59 .
drwxrwxrwt 11 root  wheel 374 2009-04-14 20:04 ..
-rw-r--r--  1 root  wheel   0 2009-04-14 18:59 test.c
-rw-r--r--  1 brice wheel  10 2009-04-14 18:59 test.h
-rw-r--r--  1 brice wheel  20 2009-04-12 16:30 old
# match only files we own
% print -l *(U)
test.h
# match only file whose size less than 2 bytes
% print -l *(L-2)
test.c
# match only files older than 2 days
% print -l *(m-2)
old

```

It is possible to combine and/or negate several qualifiers in the same expressions
``` sh

# print executable I can read but not write
% echo *(*r^w)

```

And there's more, you can change the sort order, add a trailing distinctive character (ala ls -F).
Refer to zshexpn(1) for more information.
## What's next

In the next post, I'll talk about some other interesting things:

- History
- Prompts
- Configuration, options and startup files
- ZLE: the line editor
- Redirections
- VCS info, and git in your prompt


## newcomers, use GRML

But that's all for the moment.
Newcomer, new switchers, if you want to get bootstrapped in a glimpse, I recommend using the GRML
configuration:
``` sh

# IMPORTANT: please note that you might override an existing
# configuration file in the current working directory!
wget -O ~/.zshrc http://git.grml.org/f/grml-etc-core/etc/zsh/zshrc

```
