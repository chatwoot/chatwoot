# RuboCop RSpec

[![Join the chat at https://gitter.im/rubocop-rspec/Lobby](https://badges.gitter.im/rubocop-rspec/Lobby.svg)](https://gitter.im/rubocop-rspec/Lobby)
[![Gem Version](https://badge.fury.io/rb/rubocop-rspec.svg)](https://rubygems.org/gems/rubocop-rspec)
![CI](https://github.com/rubocop/rubocop-rspec/workflows/CI/badge.svg)

[RSpec](https://rspec.info/)-specific analysis for your projects, as an extension to
[RuboCop](https://github.com/rubocop/rubocop).

- [Installation](#installation)
  - [Upgrading to RuboCop RSpec v3.x](#upgrading-to-rubocop-rspec-v3x)
  - [Upgrading to RuboCop RSpec v2.x](#upgrading-to-rubocop-rspec-v2x)
- [Usage](#usage)
- [Documentation](#documentation)
- [The Cops](#the-cops)
- [Contributing](#contributing)
- [License](#license)

## Installation

Just install the `rubocop-rspec` gem

```bash
gem install rubocop-rspec
```

or if you use bundler put this in your `Gemfile`

```ruby
gem 'rubocop-rspec', require: false
```

### Upgrading to RuboCop RSpec v3.x

Read all the details in our [Upgrade to Version 3.x](https://docs.rubocop.org/rubocop-rspec/3.0/upgrade_to_version_3.html) document.

### Upgrading to RuboCop RSpec v2.x

Read all the details in our [Upgrade to Version 2.x](https://docs.rubocop.org/rubocop-rspec/2.0/upgrade_to_version_2.html) document.

## Usage

You need to tell RuboCop to load the RSpec extension. There are three
ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`.

```yaml
plugins: rubocop-rspec
```

Alternatively, use the following array notation when specifying multiple extensions.

```yaml
plugins:
  - rubocop-other-extension
  - rubocop-rspec
```

Now you can run `rubocop` and it will automatically load the RuboCop RSpec
cops together with the standard cops.

> [!NOTE]
> The plugin system is supported in RuboCop 1.72+. In earlier versions, use `require` instead of `plugins`.

### Command line

```bash
rubocop --plugin rubocop-rspec
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.plugins << 'rubocop-rspec'
end
```

### Code Climate

rubocop-rspec is available on Code Climate as part of the rubocop engine. [Learn More](https://marketing.codeclimate.com/changelog/55a433bbe30ba00852000fac/).

## Documentation

You can read more about RuboCop RSpec in its [official manual](https://docs.rubocop.org/rubocop-rspec).

## The Cops

All cops are located under
[`lib/rubocop/cop/rspec`](lib/rubocop/cop/rspec), and contain
examples/documentation.

In your `.rubocop.yml`, you may treat the RSpec cops just like any other
cop. For example:

```yaml
RSpec/SpecFilePathFormat:
  Exclude:
    - spec/my_poorly_named_spec_file.rb
```

## Contributing

Checkout the [contribution guidelines](.github/CONTRIBUTING.md).

## License

`rubocop-rspec` is MIT licensed. [See the accompanying file](MIT-LICENSE.md) for
the full text.
