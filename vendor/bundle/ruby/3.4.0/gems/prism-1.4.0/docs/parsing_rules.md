# Rules

This document contains information related to the rules of the parser for Ruby source code.

As an example, in the documentation of many of the fields of nodes, it's mentioned that a field follows the lexing rules for `identifier` or `constant`. This document describes what those rules are.

## Constants

Constants in Ruby begin with an upper-case letter. This is followed by any number of underscores, alphanumeric, or non-ASCII characters. The definition of "alphanumeric" and "upper-case letter" are encoding-dependent.

## Non-void expression

Most expressions in CRuby are non-void. This means the expression they represent resolves to a value. For example, `1 + 2` is a non-void expression, because it resolves to a method call. Even things like `class Foo; end` is a non-void expression, because it returns the last evaluated expression in the body of the class (or `nil`).

Certain nodes, however, are void expressions, and cannot be combined to form larger expressions.
* `BEGIN {}`, `END {}`, `alias foo bar`, and `undef foo` can only be at a statement position.
* The "jumps": `return`, `break`, `next`, `redo`, `retry` are void expressions.
* `value => pattern` is also considered a void expression.

## Identifiers

Identifiers in Ruby begin with an underscore or lower-case letter. This is followed by any number of underscores, alphanumeric, or non-ASCII characters. The definition of "alphanumeric" and "lower-case letter" are encoding-dependent.
