# Quick Notes to Help with Debugging

## Reducing

One of the most important steps is reducing the code sample to a
minimal reproduction. For example, one thing I'm debugging right now
was reported as:

```ruby
a, b, c, d, e, f, g, h, i, j = 1, *[p1, p2, p3], *[p1, p2, p3], *[p4, p5, p6]
```

This original sample has 10 items on the left-hand-side (LHS) and 1 +
3 groups of 3 (calls) on the RHS + 3 arrays + 3 splats. That's a lot.

It's already been reported (perhaps incorrectly) that this has to do
with multiple splats on the RHS, so let's focus on that. At a minimum
the code can be reduced to 2 splats on the RHS and some
experimentation shows that it needs a non-splat item to fail:

```
_, _, _ = 1, *[2], *[3]
```

and some intuition further removed the arrays:

```
_, _, _ = 1, *2, *3
```

the difference is huge and will make a ton of difference when
debugging.

## Getting something to compare

```
% rake debug3 F=file.rb
```

TODO

## Comparing against ruby / ripper:

```
% rake cmp3 F=file.rb
```

This compiles the parser & lexer and then parses file.rb using both
ruby, ripper, and ruby_parser in debug modes. The output is munged to
be as uniform as possible and diffable. I'm using emacs'
`ediff-files3` to compare these files (via `rake cmp3`) all at once,
but regular `diff -u tmp/{ruby,rp}` will suffice for most tasks.

From there? Good luck. I'm currently trying to backtrack from rule
reductions to state change differences. I'd like to figure out a way
to go from this sort of diff to a reasonable test that checks state
changes but I don't have that set up at this point.

## Adding New Grammar Productions

Ruby adds stuff to the parser ALL THE TIME. It's actually hard to keep
up with, but I've added some tools and shown what a typical workflow
looks like. Let's say you want to add ruby 2.7's "beginless range" (eg
`..42`).

Whenever there's a language feature missing, I start with comparing
the parse trees between MRI and RP:

### Structural Comparing

There's a bunch of rake tasks `compare27`, `compare26`, etc that try
to normalize and diff MRI's parse.y parse tree (just the structure of
the tree in yacc) to ruby\_parser's parse tree (racc). It's the first
thing I do when I'm adding a new version. Stub out all the version
differences, and then start to diff the structure and move
ruby\_parser towards the new changes.

Some differences are just gonna be there... but here's an example of a
real diff between MRI 2.7 and ruby_parser as of today:

```diff
     arg tDOT3 arg
     arg tDOT2
     arg tDOT3
-    tBDOT2 arg
-    tBDOT3 arg
     arg tPLUS arg
     arg tMINUS arg
     arg tSTAR2 arg
```

This is a new language feature that ruby_parser doesn't handle yet.
It's in MRI (the left hand side of the diff) but not ruby\_parser (the
right hand side) so it is a `-` or missing line.

Some other diffs will have both `+` and `-` lines. That usually
happens when MRI has been refactoring the grammar. Sometimes I choose
to adapt those refactorings and sometimes it starts to get too
difficult to maintain multiple versions of ruby parsing in a single
file.

But! This structural comparing is always a place you should look when
ruby_parser is failing to parse something. Maybe it just hasn't been
implemented yet and the easiest place to look is the diff.

### Starting Test First

The next thing I do is to add a parser test to cover that feature. I
usually start with the parser and work backwards towards the lexer as
needed, as I find it structures things properly and keeps things goal
oriented.

So, make a new parser test, usually in the versioned section of the
parser tests.

```
  def test_beginless2
    rb = "..10\n; ..a\n; c"
    pt = s(:block,
           s(:dot2, nil, s(:lit, 0).line(1)).line(1),
           s(:dot2, nil, s(:call, nil, :a).line(2)).line(2),
           s(:call, nil, :c).line(3)).line(1)

    assert_parse_line rb, pt, 1

    flunk "not done yet"
  end
```

(In this case copied and modified the tests for open ranges from 2.6)
and run it to get my first error:

```
% rake N=/beginless/

...

E

Finished in 0.021814s, 45.8421 runs/s, 0.0000 assertions/s.

  1) Error:
TestRubyParserV27#test_whatevs:
Racc::ParseError: (string):1 :: parse error on value ".." (tDOT2)
    GEMS/2.7.0/gems/racc-1.5.0/lib/racc/parser.rb:538:in `on_error'
    WORK/ruby_parser/dev/lib/ruby_parser_extras.rb:1304:in `on_error'
    (eval):3:in `_racc_do_parse_c'
    (eval):3:in `do_parse'
    WORK/ruby_parser/dev/lib/ruby_parser_extras.rb:1329:in `block in process'
    RUBY/lib/ruby/2.7.0/timeout.rb:95:in `block in timeout'
    RUBY/lib/ruby/2.7.0/timeout.rb:33:in `block in catch'
    RUBY/lib/ruby/2.7.0/timeout.rb:33:in `catch'
    RUBY/lib/ruby/2.7.0/timeout.rb:33:in `catch'
    RUBY/lib/ruby/2.7.0/timeout.rb:110:in `timeout'
    WORK/ruby_parser/dev/lib/ruby_parser_extras.rb:1317:in `process'
    WORK/ruby_parser/dev/test/test_ruby_parser.rb:4198:in `assert_parse'
    WORK/ruby_parser/dev/test/test_ruby_parser.rb:4221:in `assert_parse_line'
    WORK/ruby_parser/dev/test/test_ruby_parser.rb:4451:in `test_whatevs'
```

For starters, we know the missing production is for `tBDOT2 arg`. It
is currently blowing up because it is getting `tDOT2` and simply
doesn't know what to do with it, so it raises the error. As the diff
suggests, that's the wrong token to begin with, so it is probably time
to also create a lexer test:

```
def test_yylex_bdot2
  assert_lex3("..42",
              s(:dot2, nil, s(:lit, 42)),

              :tBDOT2,   "..", EXPR_BEG,
              :tINTEGER, "42", EXPR_NUM)

  flunk "not done yet"
end
```

This one is mostly speculative at this point. It says "if we're lexing
this string, we should get this sexp if we fully parse it, and the
lexical stream should look like this"... That last bit is mostly made
up at this point. Sometimes I don't know exactly what expression state
things should be in until I start really digging in.

At this point, I have 2 failing tests that are directing me in the
right direction. It's now a matter of digging through
`compare/parse26.y` to see how the lexer differs and implementing
it...

But this is a good start to the doco for now. I'll add more later.
