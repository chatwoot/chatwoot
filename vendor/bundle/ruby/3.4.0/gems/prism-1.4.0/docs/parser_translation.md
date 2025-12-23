# parser translation

Prism ships with the ability to translate its syntax tree into the syntax tree used by the [whitequark/parser](https://github.com/whitequark/parser) gem. This allows you to use tools built on top of the `parser` gem with the `prism` parser.

## Usage

The `parser` gem provides multiple parsers to support different versions of the Ruby grammar. This includes all of the Ruby versions going back to 1.8, as well as third-party parsers like MacRuby and RubyMotion. The `prism` gem provides another parser that uses the `prism` parser to build the syntax tree.

You can use the `prism` parser like you would any other. After requiring the parser, you should be able to call any of the regular `Parser::Base` APIs that you would normally use.

```ruby
require "prism"

Prism::Translation::Parser.parse_file("path/to/file.rb")
```

### RuboCop

Prism as a parser engine is directly supported since RuboCop 1.62. The class used for parsing is `Prism::Translation::Parser`.

First, specify `prism` in your Gemfile:

```ruby
gem "prism"
```

To use Prism with RuboCop, specify `ParserEngine` and `TargetRubyVersion` in your RuboCop configuration file:

```yaml
AllCops:
  ParserEngine: parser_prism
  TargetRubyVersion: 3.3
```

The default value for `ParserEngine` is `parser_whitequark`, which indicates the Parser gem. You need to explicitly switch it to `parser_prism` to indicate Prism. Additionally, the value for `TargetRubyVersion` must be specified as `3.3` or higher, as Prism supports parsing versions of Ruby 3.3 and higher.
The parser class is determined by the combination of values for `ParserEngine` and `TargetRubyVersion`. For example, if `TargetRubyVersion: 3.3`, parsing is performed by `Prism::Translation::Parser33`, and for `TargetRubyVersion 3.4`, parsing is performed by `Prism::Translation::Parser34`.

For further information, please refer to the RuboCop documentation:
https://docs.rubocop.org/rubocop/configuration.html#setting-the-parser-engine
