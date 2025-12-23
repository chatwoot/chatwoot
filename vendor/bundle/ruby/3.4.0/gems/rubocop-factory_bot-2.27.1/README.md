# RuboCop factory_bot

[![Join the chat at https://gitter.im/rubocop-rspec/Lobby](https://badges.gitter.im/rubocop-rspec/Lobby.svg)](https://gitter.im/rubocop-rspec/Lobby)
[![Gem Version](https://badge.fury.io/rb/rubocop-factory_bot.svg)](https://rubygems.org/gems/rubocop-factory_bot)
![CI](https://github.com/rubocop/rubocop-factory_bot/workflows/CI/badge.svg)

[factory_bot](https://github.com/thoughtbot/factory_bot/blob/main/GETTING_STARTED.md)-specific analysis for your projects, as an extension to
[RuboCop](https://github.com/rubocop/rubocop).

## Installation

Just install the `rubocop-factory_bot` gem

```bash
gem install rubocop-factory_bot
```

or if you use bundler put this in your `Gemfile`

```ruby
gem 'rubocop-factory_bot', require: false
```

## Usage

You need to tell RuboCop to load the factory_bot extension. There are three
ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`.

```yaml
plugins: rubocop-factory_bot
```

Alternatively, use the following array notation when specifying multiple extensions.

```yaml
plugins:
  - rubocop-other-extension
  - rubocop-factory_bot
```

Now you can run `rubocop` and it will automatically load the RuboCop factory_bot
cops together with the standard cops.

> [!NOTE]
> The plugin system is supported in RuboCop 1.72+. In earlier versions, use `require` instead of `plugins`.

### Command line

```bash
rubocop --plugin rubocop-factory_bot
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.plugins << 'rubocop-factory_bot'
end
```

## Documentation

You can read more about RuboCop factory_bot in its [official manual](https://docs.rubocop.org/rubocop-factory_bot).

## The Cops

All cops are located under
[`lib/rubocop/cop/factory_bot`](lib/rubocop/cop/factory_bot), and contain
examples/documentation.

In your `.rubocop.yml`, you may treat the factory_bot cops just like any other
cop. For example:

```yaml
FactoryBot/AttributeDefinedStatically:
  Exclude:
    - spec/factories/my_factory.rb
```

## Contributing

Checkout the [contribution guidelines](.github/CONTRIBUTING.md).

## License

`rubocop-factory_bot` is MIT licensed. [See the accompanying file](MIT-LICENSE.md) for
the full text.
