# ruby_parser translation

Prism ships with the ability to translate its syntax tree into the syntax tree used by the [seattlerb/ruby_parser](https://github.com/seattlerb/ruby_parser) gem. This allows you to use tools built on top of the `ruby_parser` gem with the `prism` parser.

## Usage

You can call the `parse` and `parse_file` methods on the `Prism::Translation::RubyParser` module:

```ruby
filepath = "path/to/file.rb"
Prism::Translation::RubyParser.parse_file(filepath)
```

This will return to you `Sexp` objects that mirror the result of calling `RubyParser` methods, as in:

```ruby
filepath = "path/to/file.rb"
RubyParser.new.parse(File.read(filepath), filepath)
```
