# Squasher

[![Build Status](https://travis-ci.org/jalkoby/squasher.svg?branch=master)](https://travis-ci.org/jalkoby/squasher)
[![Code Climate](https://codeclimate.com/github/jalkoby/squasher.svg)](https://codeclimate.com/github/jalkoby/squasher)
[![Gem Version](https://badge.fury.io/rb/squasher.svg)](http://badge.fury.io/rb/squasher)

Squasher compresses old ActiveRecord migrations. If you work on a big project with lots of migrations, every `rake db:migrate` might take a few seconds, or creating of a new database might take a few minutes. That's because ActiveRecord loads all those migration files. Squasher removes all the migrations and creates a single migration with the final database state of the specified date (the new migration will look like a schema).

## Attention
Prior to 0.6.2 squasher could damage your real data as generate "force" tables. Please upgrade to 0.6.2+ & manually clean "force" tag from the init migration

## Installation

You don't have to add it into your Gemfile. Just a standalone installation:

    $ gem install squasher

**@note** if you use Rbenv don't forget to run `rbenv rehash`.

If you want to share it with your rails/sinatra/etc app add the below:

```ruby
# Yep, the missing group in most Gemfiles where all utilities should be!
group :tools do
  gem 'squasher', '>= 0.6.0'
  gem 'capistrano'
  gem 'rubocop'
end
```

Don't forget to run `bundle`.

To integrate `squasher` with your app even more do the below:

    $ bundle binstub squasher
    $ # and you have a runner inside the `bin` folder
    $ bin/squasher

## Usage

**@note** stop all preloading systems if there are present (spring, zeus, etc)

Suppose your application was created a few years ago. `%app_root%/db/migrate` folder looks like this:
```bash
2012...._first_migration.rb
2012...._another_migration.rb
# and a lot of other files
2013...._adding_model_foo.rb
# few years later
2016...._removing_model_foo.rb
# and so on
```

Storing these atomic changes over time is painful and useless. It's time to archive this history. Once you install the gem you can run the `squasher` command. For example, you want to compress all migrations which were created prior to the year 2017:

    $ squasher 2017        # rails 3 & 4
    $ squasher 2017 -m 5.0 # rails 5+

You can tell `squasher` a more detailed date, for example:

    $ squasher 2016/12    # prior to December 2016
    $ squasher 2016/12/19 # prior to 19 December 2016

### Options

Run `squasher -h` or just `squasher` to see how you can use squasher:

- in sql schema rails app
- in rails 5+ app
- inside an engine
- in "dry" mode
- in "reuse" mode

## Requirements

It works and was tested on Ruby 2.0+ and ActiveRecord 3.1+. It also requires a valid development configuration in `config/database.yml`.
If an old migration inserted data (created ActiveRecord model records) you will lose this code in the squashed migration, **BUT** `squasher` will ask you to leave a tmp database which will have all data that was inserted while migrating. Using this database you could add that data as another migration, or into `config/seed.rb` (the expected place for this stuff).

## Changelog

All changes are located in [the changelog file](CHANGELOG.md) with contribution notes

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
