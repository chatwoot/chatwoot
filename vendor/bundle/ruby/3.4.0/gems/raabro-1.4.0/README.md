
# raabro

[![Build Status](https://secure.travis-ci.org/floraison/raabro.svg)](http://travis-ci.org/floraison/raabro)
[![Gem Version](https://badge.fury.io/rb/raabro.svg)](http://badge.fury.io/rb/raabro)

A very dumb PEG parser library.

Son to [aabro](https://github.com/flon-io/aabro), grandson to [neg](https://github.com/jmettraux/neg), grand-grandson to [parslet](https://github.com/kschiess/parslet). There is also a javascript version [jaabro](https://github.com/jmettraux/jaabro).


## a sample parser/rewriter

You use raabro by providing the parsing rules, then some rewrite rules.

The parsing rules make use of the raabro basic parsers `seq`, `alt`, `str`, `rex`, `eseq`, ...

The rewrite rules match names passed as first argument to the basic parsers to rewrite the resulting parse trees.

```ruby
require 'raabro'


module Fun include Raabro

  # parse
  #
  # Last function is the root, "i" stands for "input".

  def pstart(i); rex(nil, i, /\(\s*/); end
  def pend(i); rex(nil, i, /\)\s*/); end
    # parenthese start and end, including trailing white space

  def comma(i); rex(nil, i, /,\s*/); end
    # a comma, including trailing white space

  def num(i); rex(:num, i, /-?[0-9]+\s*/); end
    # name is :num, a positive or negative integer

  def args(i); eseq(nil, i, :pstart, :exp, :comma, :pend); end
    # a set of :exp, beginning with a (, punctuated by commas and ending with )

  def funame(i); rex(nil, i, /[a-z][a-z0-9]*/); end
  def fun(i); seq(:fun, i, :funame, :args); end
    # name is :fun, a function composed of a function name
    # followed by arguments

  def exp(i); alt(nil, i, :fun, :num); end
    # an expression is either (alt) a function or a number

  # rewrite
  #
  # Names above (:num, :fun, ...) get a rewrite_xxx function.
  # "t" stands for "tree".

  def rewrite_exp(t); rewrite(t.children[0]); end
  def rewrite_num(t); t.string.to_i; end

  def rewrite_fun(t)

    funame, args = t.children

    [ funame.string ] +
    args.gather.collect { |e| rewrite(e) }
      #
      # #gather collect all the children in a tree that have
      # a name, in this example, names can be :exp, :num, :fun
  end
end


p Fun.parse('mul(1, 2)')
  # => ["mul", 1, 2]

p Fun.parse('mul(1, add(-2, 3))')
  # => ["mul", 1, ["add", -2, 3]]

p Fun.parse('mul (1, 2)')
  # => nil (doesn't accept a space after the function name)
```

This sample is available at: [doc/readme0.rb](doc/readme0.rb).

## custom rewrite()

By default, a parser gets a `rewrite(t)` that looks at the parse tree node names and calls the corresponding `rewrite_{node_name}()`.

It's OK to provide a custom `rewrite(t)` function.

```ruby
module Hello include Raabro

  def hello(i); str(:hello, i, 'hello'); end

  def rewrite(t)
    [ :ok, t.string ]
  end
end
```


## basic parsers

One makes a parser by composing basic parsers, for example:
```ruby
  def args(i); eseq(:args, i, :pa, :exp, :com, :pz); end
  def funame(i); rex(:funame, i, /[a-z][a-z0-9]*/); end
  def fun(i); seq(:fun, i, :funame, :args); end
```
where the `fun` parser is a sequence combining the `funame` parser then the `args` one. `:fun` (the first argument to the basic parser `seq`) will be the name of the resulting (local) parse tree.

Below is a list of the basic parsers provided by Raabro.

The first parameter to the basic parser is the name used by rewrite rules.
The second parameter is a `Raabro::Input` instance, mostly a wrapped string.

```ruby
def str(name, input, string)
  # matching a string

def rex(name, input, regex_or_string)
  # matching a regexp
  # no need for ^ or \A, checks the match occurs at current offset

def seq(name, input, *parsers)
  # a sequence of parsers

def alt(name, input, *parsers)
  # tries the parsers returns as soon as one succeeds

def altg(name, input, *parsers)
  # tries all the parsers, returns with the longest match

def rep(name, input, parser, min, max=0)
  # repeats the the wrapped parser

def nott(name, input, parser)
  # succeeds if the wrapped parser fails, fails if it succeeds

def ren(name, input, parser)
  # renames the output of the wrapped parser

def jseq(name, input, eltpa, seppa)
  #
  # seq(name, input, eltpa, seppa, eltpa, seppa, eltpa, seppa, ...)
  #
  # a sequence of `eltpa` parsers separated (joined) by `seppa` parsers

def eseq(name, input, startpa, eltpa, seppa, endpa)
  #
  # seq(name, input, startpa, eltpa, seppa, eltpa, seppa, ..., endpa)
  #
  # a sequence of `eltpa` parsers separated (joined) by `seppa` parsers
  # preceded by a `startpa` parser and followed by a `endpa` parser
```


## the `seq` parser and its quantifiers

`seq` is special, it understands "quantifiers": `'?'`, `'+'` or `'*'`. They make behave `seq` a bit like a classical regex.

The `'!'` (bang, not) quantifier is explained at the end of this section.

```ruby
module CartParser include Raabro

  def fruit(i)
    rex(:fruit, i, /(tomato|apple|orange)/)
  end
  def vegetable(i)
    rex(:vegetable, i, /(potato|cabbage|carrot)/)
  end

  def cart(i)
    seq(:cart, i, :fruit, '*', :vegetable, '*')
  end
    # zero or more fruits followed by zero or more vegetables
end
```

(Yes, this sample parser parses string like "appletomatocabbage", it's not very useful, but I hope you get the point about `.seq`)

The `'!'` (bang, not) quantifier is a kind of "negative lookahead".

```ruby
  def menu(i)
    seq(:menu, i, :mise_en_bouche, :main, :main, '!', :dessert)
  end
```

Lousy example, but here a main cannot follow a main.


## trees

An instance of `Raabro::Tree` is passed to `rewrite()` and `rewrite_{name}()` functions.

The most useful methods of this class are:
```ruby
class Raabro::Tree

  # Look for the first child or sub-child with the given name.
  # If the given name is nil, looks for the first child with a name (not nil).
  #
  def sublookup(name=nil)

  # Gathers all the children or sub-children with the given name.
  # If the given name is nil, gathers all the children with a name (not nil).
  # When a child matches, does not pursue gathering from the children of the
  # matching child.
  #
  def subgather(name=nil)
end
```

I'm using "child or sub-child" instead of "descendant" because once a child or sub-child matches, those methods do not consider the children or sub-children of that matching entity.

Here is a closeup on the rewrite functions of the sample parser at [doc/readme1.rb](doc/readme1.rb) (extracted from an early version of [floraison/dense](https://github.com/floraison/dense)):
```ruby
require 'raabro'

module PathParser include Raabro

  # (...)

  def rewrite_name(t); t.string; end
  def rewrite_off(t); t.string.to_i; end
  def rewrite_index(t); rewrite(t.sublookup); end
  def rewrite_path(t); t.subgather(:index).collect { |tt| rewrite(tt) }; end
end
```
Where `rewrite_index(t)` returns the result of the rewrite of the first of its children that has a name and `rewrite_path(t)` collects the result of the rewrite of all of its children that have the "index" name.


## errors

By default, a parser will return nil when it cannot successfully parse the input.

For example, given the above [`Fun` parser](#a-sample-parserrewriter), parsing some truncated input would yield `nil`:
```ruby
tree = Sample::Fun.parse('f(a, b')
  # yields `nil`...
```

One can reparse with `error: true` and receive an error array with the parse error details:
```ruby
err = Sample::Fun.parse('f(a, b', error: true)
  # yields:
  # [ line, column, offest, error_message, error_visual ]
[ 1, 4, 3, 'parsing failed .../:exp/:fun/:arg', "f(a, b\n   ^---" ]
```

The last string in the error array looks like when printed out:
```
f(a, b
   ^---
```

### error when not all is consumed

Consider the following toy parser:
```ruby
module ToPlus include Raabro

  # parse

  def to_plus(input); rep(:tos, input, :to, 1); end

  # rewrite

  def rewrite(t); [ :ok, t.string ]; end
end
```

```ruby
Sample::ToPlus.parse('totota')
  # yields nil since all the input was not parsed, "ta" is remaining

Sample::ToPlus.parse('totota', all: false)
  # yields
[ :ok, "toto" ]
  # and doesn't care about the remaining input "ta"

Sample::ToPlus.parse('totota', error: true)
  # yields
[ 1, 5, 4, "parsing failed, not all input was consumed", "totota\n    ^---" ]
```

The last string in the error array looks like when printed out:
```
totota
    ^---
```


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

