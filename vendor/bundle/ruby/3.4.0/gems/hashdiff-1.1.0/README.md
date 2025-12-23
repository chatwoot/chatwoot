# Hashdiff [![Build Status](https://secure.travis-ci.org/liufengyun/hashdiff.svg)](http://travis-ci.org/liufengyun/hashdiff) [![Gem Version](https://badge.fury.io/rb/hashdiff.svg)](http://badge.fury.io/rb/hashdiff)

Hashdiff is a ruby library to compute the smallest difference between two hashes.

It also supports comparing two arrays.

Hashdiff does not monkey-patch any existing class. All features are contained inside the `Hashdiff` module.

**Docs**: [Documentation](http://rubydoc.info/gems/hashdiff)


__WARNING__: Don't use the library for comparing large arrays, say ~10K (see #49).

## Why Hashdiff?

Given two Hashes A and B, sometimes you face the question: what's the smallest modification that can be made to change A into B?

An algorithm that responds to this question has to do following:

* Generate a list of additions, deletions and changes, so that `A + ChangeSet = B` and `B - ChangeSet = A`.
* Compute recursively -- Arrays and Hashes may be nested arbitrarily in A or B.
* Compute the smallest change -- it should recognize similar child Hashes or child Arrays between A and B.

Hashdiff answers the question above using an opinionated approach:

* Hash can be represented as a list of (dot-syntax-path, value) pairs. For example, `{a:[{c:2}]}` can be represented as `["a[0].c", 2]`.
* The change set can be represented using the dot-syntax representation. For example, `[['-', 'b.x', 3], ['~', 'b.z', 45, 30], ['+', 'b.y', 3]]`.
* It compares Arrays using the [LCS(longest common subsequence)](http://en.wikipedia.org/wiki/Longest_common_subsequence_problem) algorithm.
* It recognizes similar Hashes in an Array using a similarity value (0 < similarity <= 1).

## Usage

To use the gem, add the following to your Gemfile:

```Ruby
gem 'hashdiff'
```

## Quick Start

### Diff

Two simple hashes:

```ruby
a = {a:3, b:2}
b = {}

diff = Hashdiff.diff(a, b)
diff.should == [['-', 'a', 3], ['-', 'b', 2]]
```

More complex hashes:

```ruby
a = {a:{x:2, y:3, z:4}, b:{x:3, z:45}}
b = {a:{y:3}, b:{y:3, z:30}}

diff = Hashdiff.diff(a, b)
diff.should == [['-', 'a.x', 2], ['-', 'a.z', 4], ['-', 'b.x', 3], ['~', 'b.z', 45, 30], ['+', 'b.y', 3]]
```

Arrays in hashes:

```ruby
a = {a:[{x:2, y:3, z:4}, {x:11, y:22, z:33}], b:{x:3, z:45}}
b = {a:[{y:3}, {x:11, z:33}], b:{y:22}}

diff = Hashdiff.best_diff(a, b)
diff.should == [['-', 'a[0].x', 2], ['-', 'a[0].z', 4], ['-', 'a[1].y', 22], ['-', 'b.x', 3], ['-', 'b.z', 45], ['+', 'b.y', 22]]
```

### Patch

patch example:

```ruby
a = {'a' => 3}
b = {'a' => {'a1' => 1, 'a2' => 2}}

diff = Hashdiff.diff(a, b)
Hashdiff.patch!(a, diff).should == b
```

unpatch example:

```ruby
a = [{'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5}, {'x' => 5, 'y' => 6, 'z' => 3}, 1]
b = [1, {'a' => 1, 'b' => 2, 'c' => 3, 'e' => 5}]

diff = Hashdiff.diff(a, b) # diff two array is OK
Hashdiff.unpatch!(b, diff).should == a
```

### Options

The following options are available: `:delimiter`, `:similarity`, `:strict`, `:ignore_keys`,
`:indifferent`, `:numeric_tolerance`, `:strip`, `:case_insensitive`, `:array_path` and `:use_lcs`

#### `:delimiter`

You can specify `:delimiter` to be something other than the default dot. For example:

```ruby
a = {a:{x:2, y:3, z:4}, b:{x:3, z:45}}
b = {a:{y:3}, b:{y:3, z:30}}

diff = Hashdiff.diff(a, b, delimiter: '\t')
diff.should == [['-', 'a\tx', 2], ['-', 'a\tz', 4], ['-', 'b\tx', 3], ['~', 'b\tz', 45, 30], ['+', 'b\ty', 3]]
```

#### `:similarity`

In cases where you have similar hash objects in arrays, you can pass a custom value for `:similarity` instead of the default `0.8`.  This is interpreted as a ratio of similarity (default is 80% similar, whereas `:similarity => 0.5` would look for at least a 50% similarity).

#### `:strict`

The `:strict` option, which defaults to `true`, specifies whether numeric types are compared on type as well as value.  By default, an Integer will never be equal to a Float (e.g. 4 != 4.0).  Setting `:strict` to false makes the comparison looser (e.g. 4 == 4.0).

#### `:ignore_keys`

The `:ignore_keys` option allows you to specify one or more keys to ignore, which defaults to `[]` (none). Ignored keys are ignored at all levels. For example:

```ruby
a = { a: 1, b: { d: 2, a: 3 }, c: 4 }
b = { a: 2, b: { d: 2, a: 7 }, c: 5 }
diff = Hashdiff.diff(a, b, ignore_keys: :a)
diff.should == [['~', 'c', 4, 5]]
```
If you wish instead to ignore keys at a particlar level you should 
use a [custom comparison method](https://github.com/liufengyun/hashdiff#specifying-a-custom-comparison-method) instead. For example:

```ruby
a = { a: 1, b: { d: 2, a: 3 }, c: 4 }
b = { a: 2, b: { d: 2, a: 7 }, c: 5 }
diff = Hashdiff.diff(a, b) { |path, _e, _a| true if path == 'b.a' } # note '.' is the default delimiter
diff.should == [['~', 'a', 1, 2], ['~', 'c', 4, 5]]
``` 

#### `:indifferent`

The `:indifferent` option, which defaults to `false`, specifies whether to treat hash keys indifferently.  Setting `:indifferent` to true has the effect of ignoring differences between symbol keys (ie. {a: 1} ~= {'a' => 1})

#### `:numeric_tolerance`

The :numeric_tolerance option allows for a small numeric tolerance.

```ruby
a = {x:5, y:3.75, z:7}
b = {x:6, y:3.76, z:7}

diff = Hashdiff.diff(a, b, numeric_tolerance: 0.1)
diff.should == [["~", "x", 5, 6]]
```

#### `:strip`

The :strip option strips all strings before comparing.

```ruby
a = {x:5, s:'foo '}
b = {x:6, s:'foo'}

diff = Hashdiff.diff(a, b, numeric_tolerance: 0.1, strip: true)
diff.should == [["~", "x", 5, 6]]
```

#### `:case_insensitive`

The :case_insensitive option makes string comparisons ignore case.

```ruby
a = {x:5, s:'FooBar'}
b = {x:6, s:'foobar'}

diff = Hashdiff.diff(a, b, numeric_tolerance: 0.1, case_insensitive: true)
diff.should == [["~", "x", 5, 6]]
```

#### `:array_path`

The :array_path option represents the path of the diff in an array rather than
a string. This can be used to show differences in between hash key types and
is useful for `patch!` when used on hashes without string keys.

```ruby
a = {x:5}
b = {'x'=>6}

diff = Hashdiff.diff(a, b, array_path: true)
diff.should == [['-', [:x], 5], ['+', ['x'], 6]]
```

For cases where there are arrays in paths their index will be added to the path.
```ruby
a = {x:[0,1]}
b = {x:[0,2]}

diff = Hashdiff.diff(a, b, array_path: true)
diff.should == [["-", [:x, 1], 1], ["+", [:x, 1], 2]]
```

This shouldn't cause problems if you are comparing an array with a hash:

```ruby
a = {x:{0=>1}}
b = {x:[1]}

diff = Hashdiff.diff(a, b, array_path: true)
diff.should == [["~", [:x], {0=>1}, [1]]]
```

#### `:use_lcs`

The :use_lcs option is used to specify whether a
[Longest common subsequence](https://en.wikipedia.org/wiki/Longest_common_subsequence_problem)
(LCS) algorithm is used to determine differences in arrays. This defaults to
`true` but can be changed to `false` for significantly faster array comparisons
(O(n) complexity rather than O(n<sup>2</sup>) for LCS).

When :use_lcs is false the results of array comparisons have a tendency to
show changes at indexes rather than additions and subtractions when :use_lcs is
true.

Note, currently the :similarity option has no effect when :use_lcs is false.

```ruby
a = {x: [0, 1, 2]}
b = {x: [0, 2, 2, 3]}

diff = Hashdiff.diff(a, b, use_lcs: false)
diff.should == [["~", "x[1]", 1, 2], ["+", "x[3]", 3]]
```

#### Specifying a custom comparison method

It's possible to specify how the values of a key should be compared.

```ruby
a = {a:'car', b:'boat', c:'plane'}
b = {a:'bus', b:'truck', c:' plan'}

diff = Hashdiff.diff(a, b) do |path, obj1, obj2|
  case path
  when  /a|b|c/
    obj1.length == obj2.length
  end
end

diff.should == [['~', 'b', 'boat', 'truck']]
```

The yielded params of the comparison block is `|path, obj1, obj2|`, in which path is the key (or delimited compound key) to the value being compared. When comparing elements in array, the path is with the format `array[*]`. For example:

```ruby
a = {a:'car', b:['boat', 'plane'] }
b = {a:'bus', b:['truck', ' plan'] }

diff = Hashdiff.diff(a, b) do |path, obj1, obj2|
  case path
  when 'b[*]'
    obj1.length == obj2.length
  end
end

diff.should == [["~", "a", "car", "bus"], ["~", "b[1]", "plane", " plan"], ["-", "b[0]", "boat"], ["+", "b[0]", "truck"]]
```

When a comparison block is given, it'll be given priority over other specified options. If the block returns value other than `true` or `false`, then the two values will be compared with other specified options.

When used in conjunction with the `array_path` option, the path passed in as an argument will be an array. When determining the ordering of an array a key of `"*"` will be used in place of the `key[*]` field. It is possible, if you have hashes with integer or `"*"` keys, to have problems distinguishing between arrays and hashes - although this shouldn't be an issue unless your data is very difficult to predict and/or your custom rules are very specific.

#### Sorting arrays before comparison

An order difference alone between two arrays can create too many diffs to be useful. Consider sorting them prior to diffing.

```ruby
a = {a:'car', b:['boat', 'plane'] }
b = {a:'car', b:['plane', 'boat'] }

Hashdiff.diff(a, b).should == [["+", "b[0]", "plane"], ["-", "b[2]", "plane"]]

b[:b].sort!

Hashdiff.diff(a, b).should == []
```

## Maintainers

- Krzysztof Rybka ([@krzysiek1507](https://github.com/krzysiek1507))
- Fengyun Liu ([@liufengyun](https://github.com/liufengyun))

## License

Hashdiff is distributed under the MIT-LICENSE.
