# RuboCop Performance

[![Gem Version](https://badge.fury.io/rb/rubocop-performance.svg)](https://badge.fury.io/rb/rubocop-performance)
[![CI](https://github.com/rubocop/rubocop-performance/actions/workflows/test.yml/badge.svg)](https://github.com/rubocop/rubocop-performance/actions/workflows/test.yml)
[![Discord](https://img.shields.io/badge/chat-on%20discord-7289da.svg?sanitize=true)](https://discord.gg/wJjWvGRDmm)

Performance optimization analysis for your projects, as an extension to [RuboCop](https://github.com/rubocop/rubocop).

## Installation

Just install the `rubocop-performance` gem

```sh
$ gem install rubocop-performance
```

or if you use bundler put this in your `Gemfile`

```ruby
gem 'rubocop-performance', require: false
```

## Usage

You need to tell RuboCop to load the Performance extension. There are three
ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`.

```yaml
plugins: rubocop-performance
```

Alternatively, use the following array notation when specifying multiple extensions.

```yaml
plugins:
  - rubocop-other-extension
  - rubocop-performance
```

Now you can run `rubocop` and it will automatically load the RuboCop Performance
cops together with the standard cops.

> [!NOTE]
> The plugin system is supported in RuboCop 1.72+. In earlier versions, use `require` instead of `plugins`.

### Command line

```sh
$ rubocop --plugin rubocop-performance
```

### Rake task

```ruby
require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.plugins << 'rubocop-performance'
end
```

## The Cops

All cops are located under
[`lib/rubocop/cop/performance`](lib/rubocop/cop/performance), and contain
examples/documentation.

In your `.rubocop.yml`, you may treat the Performance cops just like any other
cop. For example:

```yaml
Performance/Size:
  Exclude:
    - lib/example.rb
```

## Documentation

You can read a lot more about RuboCop Performance in its [official docs](https://docs.rubocop.org/rubocop-performance/).

## Compatibility

RuboCop Performance complies with the RuboCop core compatibility.

See the [compatibility documentation](https://docs.rubocop.org/rubocop/compatibility.html) for further details.

**Note:** Performance cops are all MRI focused and are highly dependent of the version of MRI you're using.

## Contributing

Checkout the [contribution guidelines](CONTRIBUTING.md).

## License

`rubocop-performance` is MIT licensed. [See the accompanying file](LICENSE.txt) for
the full text.
