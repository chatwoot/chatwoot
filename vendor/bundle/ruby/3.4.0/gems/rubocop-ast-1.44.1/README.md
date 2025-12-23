# RuboCop AST

[![Gem Version](https://badge.fury.io/rb/rubocop-ast.svg)](https://badge.fury.io/rb/rubocop-ast)
[![CI](https://github.com/rubocop/rubocop-ast/actions/workflows/rubocop.yml/badge.svg)](https://github.com/rubocop/rubocop-ast/actions/workflows/rubocop.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a29666e6373bc41bc0a9/test_coverage)](https://codeclimate.com/github/rubocop/rubocop-ast/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/a29666e6373bc41bc0a9/maintainability)](https://codeclimate.com/github/rubocop/rubocop-ast/maintainability)

Contains the classes needed by [RuboCop](https://github.com/rubocop/rubocop) to deal with Ruby's AST, in particular:

* `RuboCop::AST::Node` ([doc](docs/modules/ROOT/pages/node_types.adoc))
* `RuboCop::AST::NodePattern` ([doc](docs/modules/ROOT/pages/node_pattern.adoc))

This gem may be used independently from the main RuboCop gem. It was extracted from RuboCop in version 0.84 and its only
dependency is the [parser](https://github.com/whitequark/parser) gem, which `rubocop-ast` extends.

## Installation

Just install the `rubocop-ast` gem

```sh
gem install rubocop-ast
```

or if you use bundler put this in your `Gemfile`

```ruby
gem 'rubocop-ast'
```

## Usage

Refer to the documentation of [`RuboCop::AST::Node`](docs/modules/ROOT/pages/node_types.adoc) and [`RuboCop::AST::NodePattern`](docs/modules/ROOT/pages/node_pattern.adoc)

See the [docs site](https://docs.rubocop.org/rubocop-ast) for more details.

### Parser compatibility switches

This gem, by default, uses most [legacy AST output from parser](https://github.com/whitequark/parser/#usage), except for the following which are set to `true`:
* `emit_forward_arg`
* `emit_match_pattern`

The main `RuboCop` gem uses these defaults (and is currently only compatible with these), but this gem can be used separately from `RuboCop` and is meant to be compatible with all settings. For example, to have `-> { ... }` emitted
as `LambdaNode` instead of `SendNode`:

```ruby
RuboCop::AST::Builder.emit_lambda = true
```

## Contributing

Checkout the [contribution guidelines](CONTRIBUTING.md).

## License

`rubocop-ast` is MIT licensed. [See the accompanying file](LICENSE.txt) for
the full text.
