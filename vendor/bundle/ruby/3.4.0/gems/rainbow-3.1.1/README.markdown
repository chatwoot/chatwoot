# Rainbow

[![Gem Version](https://badge.fury.io/rb/rainbow.svg)](https://rubygems.org/gems/rainbow)
[![Build Status](https://travis-ci.org/sickill/rainbow.svg?branch=master)](https://travis-ci.org/sickill/rainbow)
[![Build status](https://ci.appveyor.com/api/projects/status/vq4acb2c38642s5q?svg=true)](https://ci.appveyor.com/project/sickill/rainbow)
[![Code Climate](https://codeclimate.com/github/sickill/rainbow.svg)](https://codeclimate.com/github/sickill/rainbow)
[![Coverage Status](https://coveralls.io/repos/sickill/rainbow/badge.svg)](https://coveralls.io/r/sickill/rainbow)

Rainbow is a ruby gem for colorizing printed text on ANSI terminals.

It provides a string presenter object, which adds several methods to your
strings for wrapping them in [ANSI escape
codes](http://en.wikipedia.org/wiki/ANSI_escape_code). These codes when printed
in a terminal change text attributes like text color, background color,
intensity etc.

## Usage

To make your string colored wrap it with `Rainbow()` presenter and call
`.color(<color name>)` on it.

### Example

```ruby
require 'rainbow'

puts Rainbow("this is red").red + " and " + Rainbow("this on yellow bg").bg(:yellow) + " and " + Rainbow("even bright underlined!").underline.bright

# => "\e[31mthis is red\e[0m and \e[43mthis on yellow bg\e[0m and \e[4m\e[1meven bright underlined!\e[0m"
```

![Screenshot of the previous code in a terminal](https://user-images.githubusercontent.com/132/132943811-93747cc5-bdaf-43a2-a1a4-a1f18e805eba.png)

Or, [watch this video example](https://asciinema.org/a/J928KpHoUQ0sl54ulOSOLE71E?rows=20&speed=2.5)

### Rainbow presenter API

Rainbow presenter adds the following methods to presented string:

* `color(c)` (with `foreground`, and `fg` aliases)
* `background(c)` (with `bg` alias)
* `bright`
* `underline`
* `blink`
* `inverse`
* `hide`
* `faint` (not well supported by terminal emulators)
* `italic` (not well supported by terminal emulators)
* `cross_out`, `strike`

Text color can also be changed by calling a method named by a color:

* `black`
* `red`
* `green`
* `yellow`
* `blue`
* `magenta`
* `cyan`
* `white`
* `aqua`
* `silver`
* `aliceblue`
* `indianred`

All of the methods return `self` (the presenter object) so you can chain method
calls:

```ruby
Rainbow("hola!").blue.bright.underline
```

### Refinement

If you want to use the Refinements version, you can:

```ruby
require 'rainbow/refinement'
using Rainbow
puts "Hi!".green
```

Here's an IRB session example:

```
>> 'Hello, World!'.blue.bright.underline
NoMethodError: undefined method `blue' for "Hello, World!":String
    (ripl):1:in `<main>'
>> using Rainbow
=> main
>> 'Hello, World!'.blue.bright.underline
=> "\e[34m\e[1m\e[4mHello, World!\e[0m"
```

### Color specification

Both `color` and `background` accept color specified in any
of the following ways:

* ANSI color number (where 0 is black, 1 is red, 2 is green and so on):
  `Rainbow("hello").color(1)`

* [ANSI color](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors) name or [X11 color](https://en.wikipedia.org/wiki/X11_color_names) name as a symbol:
  `Rainbow("hello").color(:yellow)`.
  This can be simplified to `Rainbow("hello").yellow`  
  
  See [Color list](#user-content-color-list) for all available color names.  
  Note that ANSI colors can be changed in accordance with terminal setting.  
  But X11 color is just a syntax sugar for RGB triplet. So you always see what you specified.

* RGB triplet as separate values in the range 0-255:
  `Rainbow("hello").color(115, 23, 98)`

* RGB triplet as a hex string:
  `Rainbow("hello").color("FFC482")` or `Rainbow("hello").color("#FFC482")`

When you specify a color with a RGB triplet rainbow finds the nearest match
from 256 colors palette. Note that it requires a 256-colors capable terminal to
display correctly.

#### Example: Choose a random color

You can pick a random color with Rainbow, it's a one-liner:

```ruby
colors = Range.new(0,7).to_a
"whoop dee doop".chars.map { |char| Rainbow(char).color(colors.sample) }.join
# => "\e[36mw\e[0m\e[37mh\e[0m\e[34mo\e[0m\e[34mo\e[0m\e[37mp\e[0m\e[34m \e[0m\e[36md\e[0m\e[33me\e[0m\e[34me\e[0m\e[37m \e[0m\e[32md\e[0m\e[35mo\e[0m\e[33mo\e[0m\e[36mp\e[0m"

colors = [:aliceblue, :antiquewhite, :aqua, :aquamarine, :azure, :beige, :bisque, :blanchedalmond, :blueviolet]
"whoop dee doop".chars.map { |char| Rainbow(char).color(colors.sample) }.join
# => "\e[38;5;135mw\e[0m\e[38;5;230mh\e[0m\e[38;5;231mo\e[0m\e[38;5;135mo\e[0m\e[38;5;231mp\e[0m\e[38;5;231m \e[0m\e[38;5;122md\e[0m\e[38;5;231me\e[0m\e[38;5;231me\e[0m\e[38;5;230m \e[0m\e[38;5;122md\e[0m\e[38;5;51mo\e[0m\e[38;5;51mo\e[0m\e[38;5;51mp\e[0m"
```

### Configuration

Rainbow can be enabled/disabled globally by setting:

```ruby
Rainbow.enabled = true/false
```

When disabled all the methods return an unmodified string
(`Rainbow("hello").red == "hello"`).

It's enabled by default, unless STDOUT/STDERR is not a TTY or a terminal is
dumb.

### Advanced usage

`Rainbow()` and `Rainbow.enabled` operate on the global Rainbow wrapper
instance. If you would like to selectively enable/disable coloring in separate
parts of your application you can get a new Rainbow wrapper instance for each
of them and control the state of coloring during the runtime.

```ruby
rainbow_one = Rainbow.new
rainbow_two = Rainbow.new

rainbow_one.enabled = false

Rainbow("hello").red          # => "\e[31mhello\e[0m" ("hello" if not on TTY)
rainbow_one.wrap("hello").red # => "hello"
rainbow_two.wrap("hello").red # => "\e[31mhello\e[0m" ("hello" if not on TTY)
```

By default each new instance inherits enabled/disabled state from the global
`Rainbow.enabled`.

This feature comes handy for example when you have multiple output formatters
in your application and some of them print to a terminal but others write to a
file. Normally rainbow would detect that STDIN/STDERR is a TTY and would
colorize all the strings, even the ones that go through file writing
formatters. You can easily solve that by disabling coloring for the Rainbow
instances that are used by formatters with file output.

## Installation

Add it to your Gemfile:

```ruby
gem 'rainbow'
```

Or just install it via rubygems:

```ruby
gem install rainbow
```

## Color list

### ANSI colors

`black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`

### X11 colors

`aliceblue`, `antiquewhite`, `aqua`, `aquamarine`, `azure`, `beige`, `bisque`,
`blanchedalmond`, `blueviolet`, `brown`, `burlywood`, `cadetblue`, `chartreuse`,
`chocolate`, `coral`, `cornflower`, `cornsilk`, `crimson`, `darkblue`,
`darkcyan`, `darkgoldenrod`, `darkgray`, `darkgreen`, `darkkhaki`,
`darkmagenta`, `darkolivegreen`, `darkorange`, `darkorchid`, `darkred`,
`darksalmon`, `darkseagreen`, `darkslateblue`, `darkslategray`, `darkturquoise`,
`darkviolet`, `deeppink`, `deepskyblue`, `dimgray`, `dodgerblue`, `firebrick`,
`floralwhite`, `forestgreen`, `fuchsia`, `gainsboro`, `ghostwhite`, `gold`,
`goldenrod`, `gray`, `greenyellow`, `honeydew`, `hotpink`, `indianred`,
`indigo`, `ivory`, `khaki`, `lavender`, `lavenderblush`, `lawngreen`,
`lemonchiffon`, `lightblue`, `lightcoral`, `lightcyan`, `lightgoldenrod`,
`lightgray`, `lightgreen`, `lightpink`, `lightsalmon`, `lightseagreen`,
`lightskyblue`, `lightslategray`, `lightsteelblue`, `lightyellow`, `lime`,
`limegreen`, `linen`, `maroon`, `mediumaquamarine`, `mediumblue`,
`mediumorchid`, `mediumpurple`, `mediumseagreen`, `mediumslateblue`,
`mediumspringgreen`, `mediumturquoise`, `mediumvioletred`, `midnightblue`,
`mintcream`, `mistyrose`, `moccasin`, `navajowhite`, `navyblue`, `oldlace`,
`olive`, `olivedrab`, `orange`, `orangered`, `orchid`, `palegoldenrod`,
`palegreen`, `paleturquoise`, `palevioletred`, `papayawhip`, `peachpuff`,
`peru`, `pink`, `plum`, `powderblue`, `purple`, `rebeccapurple`, `rosybrown`,
`royalblue`, `saddlebrown`, `salmon`, `sandybrown`, `seagreen`, `seashell`,
`sienna`, `silver`, `skyblue`, `slateblue`, `slategray`, `snow`, `springgreen`,
`steelblue`, `tan`, `teal`, `thistle`, `tomato`, `turquoise`, `violet`,
`webgray`, `webgreen`, `webmaroon`, `webpurple`, `wheat`, `whitesmoke`,
`yellowgreen`

## Authors

[Marcin Kulik](http://ku1ik.com/) and [great open-source contributors](https://github.com/sickill/rainbow/graphs/contributors).
