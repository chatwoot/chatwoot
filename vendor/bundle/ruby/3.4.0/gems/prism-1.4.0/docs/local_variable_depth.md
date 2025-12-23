# Local variable depth

One feature of Prism is that it resolves local variables as it parses. It's necessary to do this because of ambiguities in the grammar. For example, consider the following code:

```ruby
foo / bar#/
```

If `foo` is a local variable, this is a call to `/` with `bar` as an argument, followed by a comment. If it's not a local variable, this is a method call to `foo` with a regular expression argument.

"Depth" refers to the number of visible scopes that Prism has to go up to find the declaration of a local variable.
Note that this follows the same scoping rules as Ruby, so a local variable is only visible in the scope it is declared in and in blocks nested in that scope.
The rules for calculating the depth are very important to understand because they may differ from individual Ruby implementations since they are not specified by the language.

Prism uses the minimum number of scopes, i.e., it only creates scopes when necessary semantically, in other words when there must be distinct scopes (which can be observed through `binding.local_variables`).
That are no "transparent/invisible" scopes in Prism.
Some Ruby implementations use those for some language constructs and need to adjust by maintaining a depth offset.

Below are the places where a local variable can be written/targeted, along with how the depth is calculated at that point.

## General

In the course of general Ruby code when reading a local variable, the depth is equal to the number of scopes to go up to find the declaration of that variable. For example:

```ruby
foo = 1
bar = 2
baz = 3

foo # depth 0
tap { bar } # depth 1
tap { tap { baz } } # depth 2
```

This also includes writing to a local variable, which could be writing to a local variable that is already declared. For example:

```ruby
foo = 1
bar = 2

foo = 3 # depth 0
tap { bar = 4 } # depth 1
```

This includes multiple assignment, where the same principle applies. For example:

```ruby
foo = 1
bar = 2

foo, bar = 3, 4 # depth 0
tap { foo, bar = 5, 6 } # depth 1
```

## `for` loops

`for` loops in Ruby break down to calls to `.each` with a block.
However in that case local variable reads and writes within the block will be in the same scope as the scope surrounding the `for` and not in a deeper/separate scope (surprising, but this is Ruby semantics).
For example:

```ruby
foo = 1

for e in baz
  foo # depth 0
  bar = 2 # depth 0
end

p bar # depth 0, prints 2
```

The local variable(s) used for the index of the `for` are also at the same depth (as variables inside and outside the `for`):

```ruby
for e in [1, 2] # depth 0
  e # depth 0
end

p e # depth 0, prints 2
```

## Pattern matching captures

You can target a local variable in a pattern matching expression using capture syntax. Using this syntax, you can target local variables in the current scope or in visible parent scopes. For example:

```ruby
42 => bar # depth 0
```

The example above writes to a local variable in the current scope. If the variable is already declared in a higher visible scope, it will be written to that scope instead. For example:

```ruby
foo = 1
tap { 42 => foo } # depth 1
```

## Named capture groups

You can target local variables through named capture groups in regular expressions if they are used on the left-hand side of a `=~` operator. For example:

```ruby
/(?<foo>\d+)/ =~ "42" # depth 0
```

This will write to a `foo` local variable. If the variable is already declared in a higher visible scope, it will be written to that scope instead. For example:

```ruby
foo = 1
tap { /(?<foo>\d+)/ =~ "42" } # depth 1
```

## "interpolated once" regular expressions

Regular expressions that interpolate local variables (unrelated to capture group local variables) and have the `o` flag will only interpolate the local variables once for the runtime of the program.
In CRuby, this is implemented by compiling the regular expression within a nested instruction sequence, which means CRuby thinks the depth is one more than prism does. For example:

```
$ ruby --dump=insns -e 'foo = 1; /#{foo}/o'
== disasm: #<ISeq:<main>@-e:1 (1,0)-(1,18)> (catch: false)
local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] foo@0
0000 putobject_INT2FIX_1_                                             (   1)[Li]
0001 setlocal_WC_0                          foo@0
0003 once                                   block in <main>, <is:0>
0006 leave

== disasm: #<ISeq:block in <main>@-e:1 (1,9)-(1,18)> (catch: false)
0000 putobject                              ""                        (   1)
0002 getlocal_WC_1                          foo@0
0004 dup
0005 objtostring                            <calldata!mid:to_s, argc:0, FCALL|ARGS_SIMPLE>
0007 anytostring
0008 toregexp                               0, 2
0011 leave
```

In this case CRuby fetches the local variable with `getlocal_WC_1` as the second instruction to the "once" instruction sequence. When compiling CRuby, prism therefore will adjust the depth to account for this difference.

## `rescue` clauses

In CRuby, `rescue` clauses are implemented as their own instruction sequence, and therefore CRuby thinks the depth is one more than prism does. For example:

```
$ ruby --dump=insns -e 'begin; foo = 1; rescue; foo; end'
== disasm: #<ISeq:<main>@-e:1 (1,0)-(1,32)> (catch: true)
== catch table
| catch type: rescue st: 0000 ed: 0004 sp: 0000 cont: 0005
| == disasm: #<ISeq:rescue in <main>@-e:1 (1,16)-(1,28)> (catch: true)
| local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
| [ 1] $!@0
| 0000 getlocal_WC_0                          $!@0                      (   1)
| 0002 putobject                              StandardError
| 0004 checkmatch                             3
| 0006 branchunless                           11
| 0008 getlocal_WC_1                          foo@0[Li]
| 0010 leave
| 0011 getlocal_WC_0                          $!@0
| 0013 throw                                  0
| catch type: retry  st: 0004 ed: 0005 sp: 0000 cont: 0000
|------------------------------------------------------------------------
local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] foo@0
0000 putobject_INT2FIX_1_                                             (   1)[Li]
0001 dup
0002 setlocal_WC_0                          foo@0
0004 nop
0005 leave
```

In the catch table, CRuby is reading the `foo` local variable using `getlocal_WC_1` as the fifth instruction to the "rescue" instruction sequence. When compiling CRuby, prism therefore will adjust the depth to account for this difference.

Note that this includes the error reference, which can target local variables, as in:

```
$ ruby --dump=insns -e 'foo = 1; begin; rescue => foo; end'              
== disasm: #<ISeq:<main>@-e:1 (1,0)-(1,34)> (catch: true)
== catch table
| catch type: rescue st: 0003 ed: 0004 sp: 0000 cont: 0005
| == disasm: #<ISeq:rescue in <main>@-e:1 (1,16)-(1,30)> (catch: true)
| local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
| [ 1] $!@0
| 0000 getlocal_WC_0                          $!@0                      (   1)
| 0002 putobject                              StandardError
| 0004 checkmatch                             3
| 0006 branchunless                           14
| 0008 getlocal_WC_0                          $!@0
| 0010 setlocal_WC_1                          foo@0
| 0012 putnil
| 0013 leave
| 0014 getlocal_WC_0                          $!@0
| 0016 throw                                  0
| catch type: retry  st: 0004 ed: 0005 sp: 0000 cont: 0003
|------------------------------------------------------------------------
local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] foo@0
0000 putobject_INT2FIX_1_                                             (   1)[Li]
0001 setlocal_WC_0                          foo@0
0003 putnil
0004 nop
0005 leave
```

Note that CRuby is writing to the `foo` local variable using the `setlocal_WC_1` instruction as the sixth instruction to the "rescue" instruction sequence. When compiling CRuby, prism therefore will adjust the depth to account for this difference.

## Post execution blocks

The `END {}` syntax allows executing code when the program exits. In CRuby, this is implemented as two nested instruction sequences. CRuby therefore thinks the depth is two more than prism does. For example:

```
$ ruby --dump=insns -e 'foo = 1; END { foo }'            
== disasm: #<ISeq:<main>@-e:1 (1,0)-(1,20)> (catch: false)
local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] foo@0
0000 putobject_INT2FIX_1_                                             (   1)[Li]
0001 setlocal_WC_0                          foo@0
0003 once                                   block in <main>, <is:0>
0006 leave

== disasm: #<ISeq:block in <main>@-e:0 (0,0)-(-1,-1)> (catch: false)
0000 putspecialobject                       1                         (   1)
0002 send                                   <calldata!mid:core#set_postexe, argc:0, FCALL>, block in <main>
0005 leave

== disasm: #<ISeq:block in <main>@-e:1 (1,9)-(1,20)> (catch: false)
0000 getlocal                               foo@0, 2                  (   1)[LiBc]
0003 leave                                  [Br]
```

In the instruction sequence corresponding to the code that gets executed inside the `END` block, CRuby is reading the `foo` local variable using `getlocal` as the second instruction to the `"block in <main>"` instruction sequence. When compiling CRuby, prism therefore will adjust the depth to account for this difference.
