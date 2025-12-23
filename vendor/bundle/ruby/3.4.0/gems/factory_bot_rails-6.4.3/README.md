# factory_bot_rails [![Code Climate][grade-image]][grade] [![Gem Version][version-image]][version]

[factory_bot][fb] is a fixtures replacement with a straightforward definition
syntax, support for multiple build strategies (saved instances, unsaved
instances, attribute hashes, and stubbed objects), and support for multiple
factories for the same class (`user`, `admin_user`, and so on), including factory
inheritance.

### Transitioning from factory\_girl\_rails?

Check out the [guide](https://github.com/thoughtbot/factory_bot/blob/4-9-0-stable/UPGRADE_FROM_FACTORY_GIRL.md).

## Rails

factory\_bot\_rails provides Rails integration for [factory_bot][fb].

Supported Rails versions are listed in [`Appraisals`](Appraisals). Supported
Ruby versions are listed in [`.github/workflows/build.yml`](.github/workflows/build.yml).

## Download

Github: http://github.com/thoughtbot/factory_bot_rails

Gem:

    $ gem install factory_bot_rails

## Configuration

Add `factory_bot_rails` to your Gemfile in both the test and development groups:

```ruby
group :development, :test do
  gem 'factory_bot_rails'
end
```

You may want to configure your test suite to include factory\_bot methods; see
[configuration](https://github.com/thoughtbot/factory_bot/blob/main/GETTING_STARTED.md#configure-your-test-suite).

### Automatic Factory Definition Loading

By default, factory\_bot\_rails will automatically load factories
defined in the following locations,
relative to the root of the Rails project:

```
factories.rb
test/factories.rb
spec/factories.rb
factories/*.rb
test/factories/*.rb
spec/factories/*.rb
```

You can configure by adding the following to `config/application.rb` or the
appropriate environment configuration in `config/environments`:

```ruby
config.factory_bot.definition_file_paths = ["custom/factories"]
```

This will cause factory\_bot\_rails to automatically load factories in
`custom/factories.rb` and `custom/factories/*.rb`.

It is possible to use this setting to share factories from a gem:

```rb
begin
  require 'factory_bot_rails'
rescue LoadError
end

class MyEngine < ::Rails::Engine
  config.factory_bot.definition_file_paths +=
    [File.expand_path('../factories', __FILE__)] if defined?(FactoryBotRails)
end
```

You can also disable automatic factory definition loading entirely by
using an empty array:

```rb
config.factory_bot.definition_file_paths = []
```

### Generators

Including factory\_bot\_rails in the development group of your Gemfile
will cause Rails to generate factories instead of fixtures.
If you want to disable this feature, you can either move factory\_bot\_rails out
of the development group of your Gemfile, or add the following configuration:

```ruby
config.generators do |g|
  g.factory_bot false
end
```

If fixture replacement is enabled and you already have a `test/factories.rb`
file (or `spec/factories.rb` if using rspec_rails), generated factories will be
inserted at the top of the existing file.
Otherwise, factories will be generated in the
`test/factories` directory (`spec/factories` if using rspec_rails),
in a file matching the name of the table (e.g. `test/factories/users.rb`).

To generate factories in a different directory, you can use the following
configuration:

```ruby
config.generators do |g|
  g.factory_bot dir: 'custom/dir/for/factories'
end
```

Note that factory\_bot\_rails will not automatically load files in custom
locations unless you add them to `config.factory_bot.definition_file_paths` as
well.

The suffix option allows you to customize the name of the generated file with a
suffix:

```ruby
config.generators do |g|
  g.factory_bot suffix: "factory"
end
```

This will generate `test/factories/users_factory.rb` instead of
`test/factories/users.rb`.

For even more customization, use the `filename_proc` option:

```ruby
config.generators do |g|
  g.factory_bot filename_proc: ->(table_name) { "prefix_#{table_name}_suffix" }
end
```

To override the [default factory template][], define your own template in
`lib/templates/factory_bot/model/factories.erb`. This template will have
access to any methods available in `FactoryBot::Generators::ModelGenerator`.
Note that factory\_bot\_rails will only use this custom template if you are
generating each factory in a separate file; it will have no effect if you are
generating all of your factories in `test/factories.rb` or `spec/factories.rb`.

Factory\_bot\_rails will add a custom generator:

```shell
rails generate factory_bot:model NAME [field:type field:type] [options]
```

[default factory template]: https://github.com/thoughtbot/factory_bot_rails/tree/main/lib/generators/factory_bot/model/templates/factories.erb

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md).

factory_bot_rails was originally written by Joe Ferris and is maintained by thoughtbot. Many improvements and bugfixes were contributed by the [open source
community](https://github.com/thoughtbot/factory_bot_rails/graphs/contributors).

## License

factory_bot_rails is Copyright © 2008-2020 Joe Ferris and thoughtbot. It is free
software, and may be redistributed under the terms specified in the
[LICENSE](LICENSE) file.

## About thoughtbot

![thoughtbot](https://thoughtbot.com/brand_assets/93:44.svg)

factory_bot_rails is maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We are passionate about open source software.
See [our other projects][community].
We are [available for hire][hire].

[fb]: https://github.com/thoughtbot/factory_bot
[grade]: https://codeclimate.com/github/thoughtbot/factory_bot_rails
[grade-image]: https://codeclimate.com/github/thoughtbot/factory_bot_rails.svg
[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github
[version-image]: https://badge.fury.io/rb/factory_bot_rails.svg
[version]: https://badge.fury.io/rb/factory_bot_rails
[hound-image]: https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg
[hound]: https://houndci.com
