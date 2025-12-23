# CHANGELOG

## 3.1.4

- Fix that skin tone modifiers were ignored when used in a non-ZWJ sequence
  context (= single emoji char + modifier) #29
- Add more docs and specs about modifier handling

## 3.1.3

Better handling of non-UTF-8 strings, patch by @Earlopain:

- Data with *BINARY* encoding is interpreted as UTF-8, if possible
- Use `invalid: :replace` and `undef: :replace` options when converting to UTF-8

## 3.1.2

- Performance improvements

## 3.1.1

- Performance improvements

## 3.1.0

**Improve Emoji support:**

- Emoji modes: Differentiate between well-formed Emoji (`:possible`) and any
  ZWJ/modifier sequence (`:all`). The latter is more common and more efficient
  to implement.
- Unify `:rgi_{fqe,mqe,uqe}` options to just `:rgi` to keep things simpler (corresponds to
  the former `:rgi_uqe` option). Most terminals that want to support the RGI set
  will probably want to catch Emoji sequences with missing VS16s.
- Add new `:all_no_vs16` and `:rgi_at` modes to be able to support some terminals
  that needs these quirks
- Add alias `emoji: :auto` for `emoji: true` and `emoji: :none` for `emoji: false`
- `:auto` mode: Only consider terminal cells when recommending Emoji support level
  (Emoji themselves might display differently)
- `:auto` mode: Set default Emoji mode for unknown/unsupported terminals to `:none`
- Rename `:basic` mode to `:vs16`

## 3.0.1


- Add WezTerm and foot as good Emoji terminals

## 3.0.0

**Rework Emoji support:**

- Emoji widths are now enabled by default
- Only reduce Emoji width to 2 when RGI Emoji detected (configurable)
- VS16 turns Emoji characters of width 1 into full-width
- Please note that Emoji parsing has a notable impact on performance.
  You can use the `emoji: false` option to disable Emoji adjustments
- Tries to detect terminal's Emoji support level automatically (from ENV vars)

**Index fixes and updates:**

- Private-use characters are considered ambiguous (were given width 1 before)
- Fix that a few zero-width ignorable codepoints from recent Unicode were missing
- Consider the following separators to be zero-width:
  - U+2028 - LINE SEPARATOR - Zl
  - U+2029 - PARAGRAPH SEPARATOR - Zp

**Other:**

- Add keyword arguments to `Unicode::DisplayWidth.of`. If you are using a hash
  with overwrite values as third parameter, be sure to put it in curly braces.
- Using third parameter or explicit hash as fourth parameter is deprecated,
  please migrate to the keyword arguments API
- Gem raises `ArgumentError` for ambiguous values other than 1 or 2
- Performance optimizations
- Require Ruby 2.5

## 2.6.0

- Unicode 16

## 2.5.0

- Unicode 15.1

## 2.4.2

More performance improvements:

- Optimize lookup of first 4096 codepoints
- Avoid overwrite lookup if no overwrites are set

## 2.4.1

- Improve general performance!
- Further improve performance for ASCII strings

*You should really upgrade - it's much faster now!*

## 2.4.0
- Improve performance for ASCII-only strings, by @fatkodima
- Require Ruby 2.4

## 2.3.0

- Unicode 15.0

## 2.2.0

- Add *Hangul Jamo Extended-B* block to zero-width chars, thanks @ninjalj #22

## 2.1.0

- Unicode 14.0

## 2.0.0

Add Support for Ruby 3.0

### Breaking Changes

Some features of this library were marked deprecated for a long time and have been removed with Version 2.0:

- Aliases of display\_width (…\_size, …\_length) have been removed
- Auto-loading of string core extension has been removed:

If you are relying on the `String#display_width` string extension to be automatically loaded (old behavior), please load it explicitly now:

```ruby
require "unicode/display_width/string_ext"
```

You could also change your `Gemfile` line to achieve this:

```ruby
gem "unicode-display_width", require: "unicode/display_width/string_ext"
```

## 2.0.0.pre2

- Update 2.0 branch to Unicode 13

## 2.0.0.pre1

Will be published as non-pre version on rubygems.org when Ruby 3.0 is released (December 2020)

- Introduce new class-based API, which remembers your string-width configuration. See README for details.
- Remove auto-loading of string extension
  - You can: `require "unicode/display_width/string_ext"` to continue to use the string extension
  - The manual opt-out `require "unicode/display_width/no_string_ext"` is not needed anymore and will
    issue a warning in the future
- Remove (already deprecated) String#display_size and String#display_width aliases

Refactorings / Internal Changes:

- Freeze string literals
- The Unicode::DisplayWidth now is class, instead of a module, this enables the new config-object API

## 1.8.0

- Unicode 14.0 (last release of 1.x)

## 1.7.0

- Unicode 13

## 1.6.1

- Fix that ambiguous and overwrite options where ignored for emoji-measuring

## 1.6.0

- Unicode 12.1

## 1.5.0

- Unicode 12

## 1.4.1

- Only bundle required lib/* and data/* files in actual rubygem, patch by @tas50

## 1.4.0

- Unicode 11

## 1.3.3

- Replace Gem::Util.gunzip with direct zlib implementation
  This removes the dependency on rubygems, fixes #17

## 1.3.2

- Explicitly load rubygems/util, fixes regression in 1.3.1 (autoload issue)

## 1.3.1

- Use `Gem::Util` for `gunzip`, removes deprecation warning, patch by @Schwad

## 1.3.0

- Unicode 10

## 1.2.1

- Fix bug that `emoji: true` would fail for emoji without modifier

## 1.2.0

- Add zero-width codepoint ranges: U+2060..U+206F, U+FFF0..U+FFF8, U+E0000..U+E0FFF
- Add full-witdh codepoint ranges: U+3400..U+4DBF, U+4E00..U+9FFF, U+F900..U+FAFF, U+20000..U+2FFFD, U+30000..U+3FFFD
- Experimental emoji support using the [unicode-emoji](https://github.com/janlelis/unicode-emoji) gem
- Fix minor bug in index compression scheme

## 1.1.3

- Fix that non-UTF-8 encodings do not throw errors, patch by @windwiny

## 1.1.2

- Reduce memory consumption and increase performance, patch by @rrosenblum

## 1.1.1

- Always load index into memory, fixes #9

## 1.1.0

- Support Unicode 9.0

## 1.0.5

- Actually include new index from 1.0.4

## 1.0.4

- New index format (much smaller) and internal API changes
- Move index generation to a builder plugin for the unicoder gem
- No public API changes

## 1.0.3

- Avoid circular dependency warning

## 1.0.2

- Fix error that gemspec might be invalid under some circumstances (see gh#6)

## 1.0.1

- Inofficially allow Ruby 1.9

## 1.0.0

- Faster than 0.3.1
- Advanced determination of character width
- This includes: Treat width of most chars of general categories (Mn, Me, Cf) as 0
- This includes: Introduce list of characters with special widths
- Allow custom overrides for specific codepoints
- Set required Ruby version to 2.0
- Add NO_STRING_EXT mode to disable monkey patching
- Internal API & index format changed drastically
- Remove require 'unicode/display_size' (use 'unicode/display_width' instead)

## 0.3.1

- Faster than 0.3.0
- Deprecate usage of aliases: String#display_size and String#display_length
- Eliminate Ruby warnings (@amatsuda)

## 0.3.0

- Update EastAsianWidth from 7.0 to 8.0
- Add rake task to update EastAsianWidth.txt
- Move code to generate index from library to Rakefile
- Update project's meta files
- Deprecate requiring 'unicode-display_size'

## 0.2.0

- Update EastAsianWidth from 6.0 to 7.0
- Don't build index table automatically when not available
- Don't include EastAsianWidth.txt in gem (only index)


## 0.1.0

- Fix github issue #1


## 0.1.0

- Initial release
