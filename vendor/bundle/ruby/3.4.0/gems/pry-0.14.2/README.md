Pry
===

[![Pry Build Status](https://github.com/pry/pry/workflows/pry/badge.svg)](https://github.com/pry/pry/actions)
[![Code Climate](https://codeclimate.com/github/pry/pry.svg)](https://codeclimate.com/github/pry/pry)
[![Gem Version](https://badge.fury.io/rb/pry.svg)](https://badge.fury.io/rb/pry)
[![Documentation Status](https://inch-ci.org/github/pry/pry.svg?branch=master)](https://inch-ci.org/github/pry/pry)
[![Downloads](https://img.shields.io/gem/dt/pry.svg?style=flat)](https://rubygems.org/gems/pry)

![Pry logo](https://www.dropbox.com/s/zp8o63kquby2rln/pry_logo_350.png?raw=1)

© John Mair ([banisterfiend](https://twitter.com/banisterfiend)) 2018<br> (Creator)

© Kyrylo Silin ([kyrylosilin](https://twitter.com/kyrylosilin)) 2018<br> (Maintainer)

**Alumni:**

* Conrad Irwin
* Ryan Fitzgerald
* Robert Gleeson

**Links:**

* https://pry.github.io/
* [YARD API documentation](https://www.rubydoc.info/gems/pry)
* [Wiki](https://github.com/pry/pry/wiki)

Table of Contents
=================

* [Introduction](#introduction)
* [Key features](#key-features)
* [Installation](#installation)
* [Overview](#overview)
   * [Commands](#commands)
   * [Navigating around state](#navigating-around-state)
   * [Runtime invocation](#runtime-invocation)
   * [Command Shell Integration](#command-shell-integration)
   * [Code Browsing](#code-browsing)
   * [Documentation Browsing](#documentation-browsing)
   * [Edit methods](#edit-methods)
   * [Live Help System](#live-help-system)
   * [Use Pry as your Rails Console](#use-pry-as-your-rails-console)
   * [Syntax Highlighting](#syntax-highlighting)
* [Supported Rubies](#supported-rubies)
* [Contact](#contact)
* [License](#license)
* [Contributors](#contributors)

Introduction
------------

Pry is a runtime developer console and IRB alternative with powerful
introspection capabilities. Pry aims to be more than an IRB replacement. It is
an attempt to bring REPL driven programming to the Ruby language.

Key features
------------

* Source code browsing (including core C source with the pry-doc gem)
* Documentation browsing
* Live help system
* Open methods in editors (`edit Class#method`)
* Syntax highlighting
* Command shell integration (start editors, run git, and rake from within Pry)
* Gist integration
* Navigation around state (`cd`, `ls` and friends)
* Runtime invocation (use Pry as a developer console or debugger)
* Exotic object support (BasicObject instances, IClasses, ...)
* A powerful and flexible command system
* Ability to view and replay history
* Many convenience commands inspired by IPython, Smalltalk and other advanced
  REPLs
* A wide-range number of
  [plugins](https://github.com/pry/pry/wiki/Available-plugins) that provide
  remote sessions, full debugging functionality, and more.

Installation
------------

### Bundler

```ruby
gem 'pry', '~> 0.13.1'
```

### Manual

```sh
gem install pry
```

Overview
--------

Pry is fairly flexible and allows significant user
[customization](https://github.com/pry/pry/wiki/Customization-and-configuration).
It is trivial to read from any object that has a `readline` method and
write to any object that has a `puts` method. Many other aspects of Pry are
also configurable, making it a good choice for implementing custom shells.

Pry comes with an executable so it can be invoked at the command line. Just
enter `pry` to start. A `pryrc` file in `$XDG_CONFIG_HOME/pry/` or the user's
home directory will be loaded if it exists. Type `pry --help` at the command
line for more information.

### Commands

Nearly every piece of functionality in a Pry session is implemented as a
command. Commands are not methods and must start at the beginning of a line,
with no whitespace in between. Commands support a flexible syntax and allow
'options' in the same way as shell commands, for example the following Pry
command will show a list of all private instance methods (in scope) that begin
with 'pa'

```ruby
pry(YARD::Parser::SourceParser):5> ls -Mp --grep ^pa
YARD::Parser::SourceParser#methods: parse  parser_class  parser_type  parser_type=  parser_type_for_filename
```

### Navigating around state

Pry allows us to pop in and out of different scopes (objects) using the `cd`
command. This enables us to explore the run-time view of a program or
library. To view which variables and methods are available within a particular
scope we use the versatile [ls
command.](https://gist.github.com/c0fc686ef923c8b87715)

Here we will begin Pry at top-level, then Pry on a class and then on an instance
variable inside that class:

```ruby
pry(main)> class Hello
pry(main)*   @x = 20
pry(main)* end
=> 20
pry(main)> cd Hello
pry(Hello):1> ls -i
instance variables: @x
pry(Hello):1> cd @x
pry(20):2> self + 10
=> 30
pry(20):2> cd ..
pry(Hello):1> cd ..
pry(main)> cd ..
```

The number after the `:` in the pry prompt indicates the nesting level. To
display more information about nesting, use the `nesting` command. E.g

```ruby
pry("friend"):3> nesting
Nesting status:
0. main (Pry top level)
1. Hello
2. 100
3. "friend"
=> nil
```

We can then jump back to any of the previous nesting levels by using the
`jump-to` command:

```ruby
pry("friend"):3> jump-to 1
=> 100
pry(Hello):1>
```

### Runtime invocation

Pry can be invoked in the middle of a running program. It opens a Pry session at
the point it's called and makes all program state at that point available. It
can be invoked on any object using the `my_object.pry` syntax or on the current
binding (or any binding) using `binding.pry`. The Pry session will then begin
within the scope of the object (or binding). When the session ends the program
continues with any modifications you made to it.

This functionality can be used for such things as: debugging, implementing
developer consoles and applying hot patches.

code:

```ruby
# test.rb
require 'pry'

class A
  def hello() puts "hello world!" end
end

a = A.new

# start a REPL session
binding.pry

# program resumes here (after pry session)
puts "program resumes here."
```

Pry session:

```ruby
pry(main)> a.hello
hello world!
=> nil
pry(main)> def a.goodbye
pry(main)*   puts "goodbye cruel world!"
pry(main)* end
=> :goodbye
pry(main)> a.goodbye
goodbye cruel world!
=> nil
pry(main)> exit

program resumes here.
```

### Command Shell Integration

A line of input that begins with a '.' will be forwarded to the command
shell. This enables us to navigate the file system, spawn editors, and run git
and rake directly from within Pry.

Further, we can use the `shell-mode` command to incorporate the present working
directory into the Pry prompt and bring in (limited at this stage, sorry) file
name completion.  We can also interpolate Ruby code directly into the shell by
using the normal `#{}` string interpolation syntax.

In the code below we're going to switch to `shell-mode` and edit the `pryrc`
file. We'll then cat its contents and reload the file.

```ruby
pry(main)> shell-mode
pry main:/home/john/ruby/projects/pry $ .cd ~
pry main:/home/john $ .emacsclient .pryrc
pry main:/home/john $ .cat .pryrc
def hello_world
  puts "hello world!"
end
pry main:/home/john $ load ".pryrc"
=> true
pry main:/home/john $ hello_world
hello world!
```

We can also interpolate Ruby code into the shell. In the example below we use
the shell command `cat` on a random file from the current directory and count
the number of lines in that file with `wc`:

```ruby
pry main:/home/john $ .cat #{Dir['*.*'].sample} | wc -l
44
```

### Code Browsing

You can browse method source code with the `show-source` command. Nearly all
Ruby methods (and some C methods, with the pry-doc gem) can have their source
viewed. Code that is longer than a page is sent through a pager (such as less),
and all code is properly syntax highlighted (even C code).

The `show-source` command accepts two syntaxes, the typical ri `Class#method`
syntax and also simply the name of a method that's in scope. You can optionally
pass the `-l` option to `show-source` to include line numbers in the output.

In the following example we will enter the `Pry` class, list the instance
methods beginning with 'se' and display the source code for the `set_last_result` method:

```ruby
pry(main)> cd Pry
pry(Pry):1> ls -M --grep se
Pry#methods: raise_up  raise_up!  raise_up_common  reset_eval_string  select_prompt  set_last_result
pry(Pry):1> show-source set_last_result -l

From: /home/john/ruby/projects/pry/lib/pry/pry_instance.rb:405:
Owner: Pry
Visibility: public
Signature: set_last_result(result, code=?)
Number of lines: 6

405: def set_last_result(result, code = "")
406:   @last_result_is_exception = false
407:   @output_ring << result
408:
409:   self.last_result = result unless code =~ /\A\s*\z/
410: end
```

Note that we can also view C methods (from Ruby Core) using the
`pry-doc` plugin; we also show off the alternate syntax for
`show-source`:

```ruby
pry(main)> show-source Array#select

From: array.c in Ruby Core (C Method):
Number of lines: 15

static VALUE
rb_ary_select(VALUE ary)
{
    VALUE result;
    long i;

    RETURN_ENUMERATOR(ary, 0, 0);
    result = rb_ary_new2(RARRAY_LEN(ary));
    for (i = 0; i < RARRAY_LEN(ary); i++) {
        if (RTEST(rb_yield(RARRAY_PTR(ary)[i]))) {
            rb_ary_push(result, rb_ary_elt(ary, i));
        }
    }
    return result;
}
```

### Documentation Browsing

One use-case for Pry is to explore a program at run-time by `cd`-ing in and out
of objects and viewing and invoking methods. In the course of exploring it may
be useful to read the documentation for a specific method that you come
across. `show-source` command supports two syntaxes - the
normal `ri` syntax as well as accepting the name of any method that is currently
in scope.

The Pry documentation system does not rely on pre-generated `rdoc` or `ri`,
instead it grabs the comments directly above the method on demand. This results
in speedier documentation retrieval and allows the Pry system to retrieve
documentation for methods that would not be picked up by `rdoc`. Pry also has a
basic understanding of both the rdoc and yard formats and will attempt to syntax
highlight the documentation appropriately.

Nonetheless, the `ri` functionality is very good and has an advantage over Pry's
system in that it allows documentation lookup for classes as well as
methods. Pry therefore has good integration with `ri` through the `ri`
command. The syntax for the command is exactly as it would be in command-line -
so it is not necessary to quote strings.

In our example we will enter the `Gem` class and view the documentation for the
`try_activate` method:

```ruby
pry(main)> cd Gem
pry(Gem):1> show-source try_activate -d

From: /Users/john/rbenv/versions/2.7.1/lib/ruby/2.7.0/rubygems.rb:194:
Owner: #<Class:Gem>
Visibility: public
Signature: try_activate(path)
Number of lines: 28

Try to activate a gem containing path. Returns true if
activation succeeded or wasn't needed because it was already
activated. Returns false if it can't find the path in a gem.

def self.try_activate(path)
  # finds the _latest_ version... regardless of loaded specs and their deps
  # if another gem had a requirement that would mean we shouldn't
  # activate the latest version, then either it would already be activated
  # or if it was ambiguous (and thus unresolved) the code in our custom
  # require will try to activate the more specific version.

  spec = Gem::Specification.find_by_path path
pry(Gem):1>
```

We can also use `ri` in the normal way:

```ruby
pry(main) ri Array#each
----------------------------------------------------------- Array#each
     array.each {|item| block }   ->   array
------------------------------------------------------------------------
     Calls _block_ once for each element in _self_, passing that element
     as a parameter.

        a = [ "a", "b", "c" ]
        a.each {|x| print x, " -- " }

     produces:

        a -- b -- c --
```

### Edit methods

You can use `edit Class#method` or `edit my_method` (if the method is in scope)
to open a method for editing directly in your favorite editor. Pry has knowledge
of a few different editors and will attempt to open the file at the line the
method is defined.

You can set the editor to use by assigning to the `Pry.editor`
accessor. `Pry.editor` will default to `$EDITOR` or failing that will use `nano`
as the backup default. The file that is edited will be automatically reloaded
after exiting the editor - reloading can be suppressed by passing the
`--no-reload` option to `edit`

In the example below we will set our default editor to "emacsclient" and open
the `Pry#repl` method for editing:

```ruby
pry(main)> Pry.editor = "emacsclient"
pry(main)> edit Pry#repl
```

### Live Help System

Many other commands are available in Pry; to see the full list type `help` at
the prompt. A short description of each command is provided with basic
instructions for use; some commands have a more extensive help that can be
accessed via typing `command_name --help`. A command will typically say in its
description if the `--help` option is available.

### Use Pry as your Rails Console

The recommended way to use Pry as your Rails console is to add [the `pry-rails`
gem](https://github.com/rweng/pry-rails) to your Gemfile. This replaces the
default console with Pry, in addition to loading the Rails console helpers and
adding some useful Rails-specific commands.

If you don't want to change your Gemfile, you can still run a Pry console in
your app's environment using Pry's `-r` flag:

```sh
pry -r ./config/environment
```

Also check out the
[wiki](https://github.com/pry/pry/wiki/Setting-up-Rails-or-Heroku-to-use-Pry)
for more information about integrating Pry with Rails.

### Syntax Highlighting

Syntax highlighting is on by default in Pry. If you want to change the colors,
check out the [pry-theme](https://github.com/kyrylo/pry-theme) gem.

You can toggle the syntax highlighting on and off in a session by using the
`toggle-color` command. Alternatively, you can turn it off permanently by
putting the line `Pry.color = false` in your `pryrc` file.

Supported Rubies
----------------

* CRuby >= 2.0.0
* JRuby >= 9.0

Contact
-------

In case you have a problem, question or a bug report, feel free to:

* ask a question on IRC (#pry on Freenode)
* [file an issue](https://github.com/pry/pry/issues)
* [tweet at us](https://twitter.com/pryruby)

License
-------

The project uses the MIT License. See LICENSE.md for details.

Contributors
------------

Pry is primarily the work of [John Mair (banisterfiend)](https://github.com/banister), for full list
of contributors see the
[contributors graph](https://github.com/pry/pry/graphs/contributors).
