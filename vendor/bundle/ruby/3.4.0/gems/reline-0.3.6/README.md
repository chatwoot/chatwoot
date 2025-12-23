[![Gem Version](https://badge.fury.io/rb/reline.svg)](https://badge.fury.io/rb/reline)
[![CI](https://github.com/ruby/reline/actions/workflows/reline.yml/badge.svg)](https://github.com/ruby/reline/actions/workflows/reline.yml)

This is a screen capture of *IRB improved by Reline*.

![IRB improved by Reline](https://raw.githubusercontent.com/wiki/ruby/reline/images/irb_improved_by_reline.gif)

# Reline

Reline is compatible with the API of Ruby's stdlib 'readline', GNU Readline and Editline by pure Ruby implementation.

## Usage

### Single line editing mode

It's compatible with the readline standard library.

See [the document of readline stdlib](https://ruby-doc.org/stdlib/libdoc/readline/rdoc/Readline.html) or [bin/example](https://github.com/ruby/reline/blob/master/bin/example).

### Multi-line editing mode

```ruby
require "reline"

prompt = 'prompt> '
use_history = true

begin
  while true
    text = Reline.readmultiline(prompt, use_history) do |multiline_input|
      # Accept the input until `end` is entered
      multiline_input.split.last == "end"
    end

    puts 'You entered:'
    puts text
  end
# If you want to exit, type Ctrl-C
rescue Interrupt
  puts '^C'
  exit 0
end
```

```bash
$ ruby example.rb
prompt> aaa
prompt> bbb
prompt> end
You entered:
aaa
bbb
end
```

See also: [test/reline/yamatanooroti/multiline_repl](https://github.com/ruby/reline/blob/master/test/reline/yamatanooroti/multiline_repl)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/reline.

### Run tests

> **Note**
> Please make sure you have `libvterm` installed for `yamatanooroti` tests (integration tests).

If you use Homebrew, you can install it by running `brew install libvterm`.

```bash
WITH_VTERM=1 bundle install
WITH_VTERM=1 bundle exec rake test test_yamatanooroti
```

## Releasing

```bash
rake release
gh release create vX.Y.Z --generate-notes
```

## License

The gem is available as open source under the terms of the [Ruby License](https://www.ruby-lang.org/en/about/license.txt).

## Acknowledgments for [rb-readline](https://github.com/ConnorAtherton/rb-readline)

In developing Reline, we have used some of the rb-readline implementation, so this library includes [copyright notice, list of conditions and the disclaimer](license_of_rb-readline) under the 3-Clause BSD License. Reline would never have been developed without rb-readline. Thank you for the tremendous accomplishments.
