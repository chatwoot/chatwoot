# Administrate::Field::BelongsToSearch

[![Build Status](https://travis-ci.org/fishbrain/administrate-field-belongs_to_search.svg?branch=master)](https://travis-ci.org/fishbrain/administrate-field-belongs_to_search)
[![Gem Version](https://badge.fury.io/rb/administrate-field-belongs_to_search.svg)](https://badge.fury.io/rb/administrate-field-belongs_to_search)
[![Coverage Status](https://coveralls.io/repos/github/fishbrain/administrate-field-belongs_to_search/badge.svg?branch=master)](https://coveralls.io/github/fishbrain/administrate-field-belongs_to_search?branch=master)

A plugin to search through `belongs_to` associations in [thoughtbot's Administrate](https://github.com/thoughtbot/administrate) Rails engine.

## Usage

Add it to your `Gemfile`:

```ruby
gem 'administrate-field-belongs_to_search'
```

Run bundler to install:

```sh
bundle install
```

Add it to your Administrate dashboard, for instance:

```ruby
class PostDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    author: Field::BelongsToSearch.with_options(class_name: 'User')
  }
# ...
```

With this, you should be good to go!

## Develop and Contribute

Fork and clone the repo. Install dependencies and run test using:

```sh
bundle install
bundle exec rake
```

Then, implement your feature/fix, [write a good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
and submit a pull request to this repository. If you only have some feedback or are unsure about how to do something, you're welcome to
submit an [issue](https://github.com/fishbrain/administrate-field-belongs_to_search/issues/new).

This is meant to be an welcoming and friendly place for collaboration. Therefore, all contributors are expected to adhere to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

## License

This plugin is Copyright © 2017 Fishbrain AB. It is licensed under the MIT license. See [LICENSE](LICENSE) for details.

## Screenshot

![Screenshot](http://i.imgur.com/4GlEJ6O.png)

========

![Fishbrain AB](http://i.imgur.com/wOMiqE8.png)

This plugin is maintained by [Fishbrain AB](https://fishbrain.com).

At Fishbrain, we're passionate about the outdoors and conservation. Together, we work to bring you the best app for fishing, hands down.

If you love working with amazing and talented people in tight-knit teams, [join us](https://fishbrain.com/jobs/)!
