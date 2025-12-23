## Unicode::DisplayWidth [![[version]](https://badge.fury.io/rb/unicode-display_width.svg)](https://badge.fury.io/rb/unicode-display_width) [<img src="https://travis-ci.org/janlelis/unicode-display_width.png" />](https://travis-ci.org/janlelis/unicode-display_width)

Determines the monospace display width of a string in Ruby. Implementation based on [EastAsianWidth.txt](https://www.unicode.org/Public/UNIDATA/EastAsianWidth.txt) and other data, 100% in Ruby. Other than [wcwidth()](https://github.com/janlelis/wcswidth-ruby), which fulfills a similar purpose, it does not rely on the OS vendor to provide an up-to-date method for measuring string width.

Unicode version: **14.0.0** (September 2021)

Supported Rubies: **2.7**, **2.6**, **2.5**, **2.4**

Old Rubies that might still work: **2.3**, **2.2**, **2.1**, **2.0**, **1.9**

## Introduction to Character Widths

Guessing the correct space a character will consume on terminals is not easy. There is no single standard. Most implementations combine data from [East Asian Width](https://www.unicode.org/reports/tr11/), some [General Categories](https://en.wikipedia.org/wiki/Unicode_character_property#General_Category), and hand-picked adjustments.

### How this Library Handles Widths

Further at the top means higher precedence. Please expect changes to this algorithm with every MINOR version update (the X in 1.X.0)!

Width  | Characters                   | Comment
-------|------------------------------|--------------------------------------------------
X      | (user defined)               | Overwrites any other values
-1     | `"\b"`                       | Backspace (total width never below 0)
0      | `"\0"`, `"\x05"`, `"\a"`, `"\n"`, `"\v"`, `"\f"`, `"\r"`, `"\x0E"`, `"\x0F"` | [C0 control codes](https://en.wikipedia.org/wiki/C0_and_C1_control_codes#C0_.28ASCII_and_derivatives.29) that do not change horizontal width
1      | `"\u{00AD}"`                 | SOFT HYPHEN
2      | `"\u{2E3A}"`                 | TWO-EM DASH
3      | `"\u{2E3B}"`                 | THREE-EM DASH
0      | General Categories: Mn, Me, Cf (non-arabic) | Excludes ARABIC format characters
0      | `"\u{1160}".."\u{11FF}"`     | HANGUL JUNGSEONG
0      | `"\u{2060}".."\u{206F}"`, `"\u{FFF0}".."\u{FFF8}"`, `"\u{E0000}".."\u{E0FFF}"` | Ignorable ranges
2      | East Asian Width: F, W       | Full-width characters
2      | `"\u{3400}".."\u{4DBF}"`, `"\u{4E00}".."\u{9FFF}"`, `"\u{F900}".."\u{FAFF}"`, `"\u{20000}".."\u{2FFFD}"`, `"\u{30000}".."\u{3FFFD}"` | Full-width ranges
1 or 2 | East Asian Width: A          | Ambiguous characters, user defined, default: 1
1      | All other codepoints         | -

## Install

Install the gem with:

    $ gem install unicode-display_width

Or add to your Gemfile:

    gem 'unicode-display_width'

## Usage

```ruby
require 'unicode/display_width'

Unicode::DisplayWidth.of("⚀") # => 1
Unicode::DisplayWidth.of("一") # => 2
```

### Ambiguous Characters

The second parameter defines the value returned by characters defined as ambiguous:

```ruby
Unicode::DisplayWidth.of("·", 1) # => 1
Unicode::DisplayWidth.of("·", 2) # => 2
```

### Custom Overwrites

You can overwrite how to handle specific code points by passing a hash (or even a proc) as third parameter:

```ruby
Unicode::DisplayWidth.of("a\tb", 1, 0x09 => 10)) # => 12
```

### Emoji Support

Experimental emoji support is included. It will adjust the string's size for modifier and zero-width joiner sequences. You will need to add the [unicode-emoji](https://github.com/janlelis/unicode-emoji) gem to your Gemfile:

```ruby
gem 'unicode-display_width'
gem 'unicode-emoji'
```

You can then activate the emoji string width adjustments by passing `emoji: true` as fourth parameter:

```ruby
Unicode::DisplayWidth.of "🤾🏽‍♀️" # => 5
Unicode::DisplayWidth.of "🤾🏽‍♀️", 1, {}, emoji: true # => 2
```

### Usage with String Extension

Activated by default. Will be deactivated in version 2.0:

```ruby
require 'unicode/display_width/string_ext'

"⚀".display_width #=> 1
'一'.display_width #=> 2
```

You can actively opt-out from the string extension with: `require 'unicode/display_width/no_string_ext'`

### Usage From the CLI

Use this one-liner to print out display widths for strings from the command-line:

```
$ gem install unicode-display_width
$ ruby -r unicode/display_width -e 'puts Unicode::DisplayWidth.of $*[0]' -- "一"
```
Replace "一" with the actual string to measure

## Other Implementations & Discussion

- Python: https://github.com/jquast/wcwidth
- JavaScript: https://github.com/mycoboco/wcwidth.js
- C: https://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c
- C for Julia: https://github.com/JuliaLang/utf8proc/issues/2

See [unicode-x](https://github.com/janlelis/unicode-x) for more Unicode related micro libraries.

## Copyright & Info

- Copyright (c) 2011, 2015-2020 Jan Lelis, https://janlelis.com, released under the MIT
license
- Early versions based on runpaint's unicode-data interface: Copyright (c) 2009 Run Paint Run Run
- Unicode data: https://www.unicode.org/copyright.html#Exhibit1
