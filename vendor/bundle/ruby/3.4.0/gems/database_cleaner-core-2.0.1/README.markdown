# Database Cleaner

[![Build Status](https://travis-ci.org/DatabaseCleaner/database_cleaner.svg?branch=master)](https://travis-ci.org/DatabaseCleaner/database_cleaner)
[![Code Climate](https://codeclimate.com/github/DatabaseCleaner/database_cleaner/badges/gpa.svg)](https://codeclimate.com/github/DatabaseCleaner/database_cleaner)
[![codecov](https://codecov.io/gh/DatabaseCleaner/database_cleaner/branch/master/graph/badge.svg)](https://codecov.io/gh/DatabaseCleaner/database_cleaner)
![Gem Version](https://badge.fury.io/rb/database_cleaner.svg)
[![SemVer](https://api.dependabot.com/badges/compatibility_score?dependency-name=database_cleaner&package-manager=bundler&version-scheme=semver)](https://dependabot.com/compatibility-score.html?dependency-name=database_cleaner&package-manager=bundler&version-scheme=semver)

Database Cleaner is a set of gems containing strategies for cleaning your database in Ruby.

The original use case was to ensure a clean state during tests.
Each strategy is a small amount of code but is code that is usually needed in any ruby app that is testing with a database.

## Gem Setup

Instead of using the `database_cleaner` gem directly, each ORM has its own gem. Most projects will only need the `database_cleaner-active_record` gem:

```ruby
# Gemfile
group :test do
  gem 'database_cleaner-active_record'
end
```

If you are using multiple ORMs, just load multiple gems:


```ruby
# Gemfile
group :test do
  gem 'database_cleaner-active_record'
  gem 'database_cleaner-redis'
end
```
## List of adapters

Here is an overview of the databases and ORMs supported by each adapter:

MySQL, PostgreSQL, SQLite, etc
 * [database_cleaner-active_record](https://github.com/DatabaseCleaner/database_cleaner-active_record)
 * [database_cleaner-sequel](https://github.com/DatabaseCleaner/database_cleaner-sequel)

MongoDB
 * [database_cleaner-mongo](https://github.com/DatabaseCleaner/database_cleaner-mongo)
 * [database_cleaner-mongoid](https://github.com/DatabaseCleaner/database_cleaner-mongoid)

Redis
 * [database_cleaner-redis](https://github.com/DatabaseCleaner/database_cleaner-redis)

More details on available configuration options can be found in the README for the specific adapter gem that you're using.

For support or to discuss development please use the [Google Group](https://groups.google.com/group/database_cleaner).

### Discontinued adapters

The following adapters have been discontinued. Please let us know on the [Google Group](https://groups.google.com/group/database_cleaner) if you think one of these should be resurrected!

 * [database_cleaner-data_mapper](https://github.com/DatabaseCleaner/database_cleaner-data_mapper)
 * [database_cleaner-couch_potato](https://github.com/DatabaseCleaner/database_cleaner-couch_potato)
 * [database_cleaner-mongo_mapper](https://github.com/DatabaseCleaner/database_cleaner-mongo_mapper)
 * [database_cleaner-moped](https://github.com/DatabaseCleaner/database_cleaner-moped)
 * [database_cleaner-neo4j](https://github.com/DatabaseCleaner/database_cleaner-neo4j)

## How to use

```ruby
require 'database_cleaner/active_record'

DatabaseCleaner.strategy = :truncation

# then, whenever you need to clean the DB
DatabaseCleaner.clean
```

With the `:truncation` strategy you can also pass in options, for example:

```ruby
DatabaseCleaner.strategy = :truncation, {:only => %w[widgets dogs some_other_table]}
```

```ruby
DatabaseCleaner.strategy = :truncation, {:except => %w[widgets]}
```

(I should point out the truncation strategy will never truncate your schema_migrations table.)

Some strategies need to be started before tests are run (for example the `:transaction` strategy needs to know to open up a transaction). This can be accomplished by calling `DatabaseCleaner.start` at the beginning of the run, or by running the tests inside a block to `DatabaseCleaner.cleaning`. So you would have:

```ruby
require 'database_cleaner/active_record'

DatabaseCleaner.strategy = :transaction

DatabaseCleaner.start # usually this is called in setup of a test

dirty_the_db

DatabaseCleaner.clean # cleanup of the test

# OR

DatabaseCleaner.cleaning do
  dirty_the_db
end
```

At times you may want to do a single clean with one strategy.

For example, you may want to start the process by truncating all the tables, but then use the faster transaction strategy the remaining time. To accomplish this you can say:

```ruby
require 'database_cleaner/active_record'

DatabaseCleaner.clean_with :truncation

DatabaseCleaner.strategy = :transaction

# then make the DatabaseCleaner.start and DatabaseCleaner.clean calls appropriately
```

## What strategy is fastest?

For the SQL libraries the fastest option will be to use `:transaction` as transactions are simply rolled back. If you can use this strategy you should. However, if you wind up needing to use multiple database connections in your tests (i.e. your tests run in a different process than your application) then using this strategy becomes a bit more difficult. You can get around the problem a number of ways.

One common approach is to force all processes to use the same database connection ([common ActiveRecord hack](http://blog.plataformatec.com.br/2011/12/three-tips-to-improve-the-performance-of-your-test-suite/)) however this approach has been reported to result in non-deterministic failures.

Another approach is to have the transactions rolled back in the application's process and relax the isolation level of the database (so the tests can read the uncommitted transactions).

An easier, but slower, solution is to use the `:truncation` or `:deletion` strategy.

So what is fastest out of `:deletion` and `:truncation`? Well, it depends on your table structure and what percentage of tables you populate in an average test. The reasoning is out of the scope of this README but here is a [good SO answer on this topic for Postgres](https://stackoverflow.com/questions/11419536/postgresql-truncation-speed/11423886#11423886).

Some people report much faster speeds with `:deletion` while others say `:truncation` is faster for them. The best approach therefore is it try all options on your test suite and see what is faster.

If you are using ActiveRecord then take a look at the [additional options](https://github.com/DatabaseCleaner/database_cleaner-active_record#strategy-configuration-options) available for `:truncation`.

Database Cleaner also includes a `null` strategy (that does no cleaning at all) which can be used with any ORM library.
You can also explicitly use it by setting your strategy to `nil`.

## Test Framework Examples

### RSpec Example

```ruby
RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

end
```

### RSpec with Capybara Example

You'll typically discover a feature spec is incorrectly using transaction
instead of truncation strategy when the data created in the spec is not
visible in the app-under-test.

A frequently occurring example of this is when, after creating a user in a
spec, the spec mysteriously fails to login with the user. This happens because
the user is created inside of an uncommitted transaction on one database
connection, while the login attempt is made using a separate database
connection. This separate database connection cannot access the
uncommitted user data created over the first database connection due to
transaction isolation.

For feature specs using a Capybara driver for an external
JavaScript-capable browser (in practice this is all drivers except
`:rack_test`), the Rack app under test and the specs do not share a
database connection.

When a spec and app-under-test do not share a database connection,
you'll likely need to use the truncation strategy instead of the
transaction strategy.

See the suggested config below to temporarily enable truncation strategy
for affected feature specs only. This config continues to use transaction
strategy for all other specs.

It's also recommended to use `append_after` to ensure `DatabaseCleaner.clean`
runs *after* the after-test cleanup `capybara/rspec` installs.

```ruby
require 'capybara/rspec'

#...

RSpec.configure do |config|

  config.use_transactional_fixtures = false

  config.before(:suite) do
    if config.use_transactional_fixtures?
      raise(<<-MSG)
        Delete line `config.use_transactional_fixtures = true` from rails_helper.rb
        (or set it to false) to prevent uncommitted transactions being used in
        JavaScript-dependent specs.

        During testing, the app-under-test that the browser driver connects to
        uses a different database connection to the database connection used by
        the spec. The app's database connection would not be able to access
        uncommitted transaction data setup over the spec's database connection.
      MSG
    end
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :feature) do
    # :rack_test driver's Rack app under test shares database connection
    # with the specs, so continue to use transaction strategy for speed.
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test

    unless driver_shares_db_connection_with_specs
      # Driver is probably for an external browser with an app
      # under test that does *not* share a database connection with the
      # specs, so use truncation strategy.
      DatabaseCleaner.strategy = :truncation
    end
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end

end
```


### Minitest Example

```ruby
DatabaseCleaner.strategy = :transaction

class Minitest::Spec
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end

# with the minitest-around gem, this may be used instead:
class Minitest::Spec
  around do |tests|
    DatabaseCleaner.cleaning(&tests)
  end
end
```

### Cucumber Example

If you're using Cucumber with Rails, just use the generator that ships with cucumber-rails, and that will create all the code you need to integrate DatabaseCleaner into your Rails project.

Otherwise, to add DatabaseCleaner to your project by hand, create a file `features/support/database_cleaner.rb` that looks like this:

```ruby
require 'database_cleaner/active_record'

DatabaseCleaner.strategy = :truncation

Around do |scenario, block|
  DatabaseCleaner.cleaning(&block)
end
```

This should cover the basics of tear down between scenarios and keeping your database clean.

For more examples see the section ["Why?"](#why).

## How to use with multiple ORMs

Sometimes you need to use multiple ORMs in your application.

You can use DatabaseCleaner to clean multiple ORMs, and multiple databases for those ORMs.

```ruby
require 'database_cleaner/active_record'
require 'database_cleaner/mongo_mapper'

# How to specify particular orms
DatabaseCleaner[:active_record].strategy = :transaction
DatabaseCleaner[:mongo_mapper].strategy = :truncation

# How to specify particular databases
DatabaseCleaner[:active_record, { db: :two }]

# You may also pass in the model directly:
DatabaseCleaner[:active_record, { db: ModelWithDifferentConnection }]
```

Usage beyond that remains the same with `DatabaseCleaner.start` calling any setup on the different configured databases, and `DatabaseCleaner.clean` executing afterwards.

## Why?

One of my motivations for writing this library was to have an easy way to turn on what Rails calls "transactional_fixtures" in my non-rails ActiveRecord projects.

After copying and pasting code to do this several times I decided to package it up as a gem and save everyone a bit of time.

## Safeguards

DatabaseCleaner comes with safeguards against:

* Running in production (checking for `ENV`, `APP_ENV`, `RACK_ENV`, and `RAILS_ENV`)
* Running against a remote database (checking for a `DATABASE_URL` that does not include `localhost`, `.local` or `127.0.0.1`)

Both safeguards can be disabled separately as follows.

Using environment variables:

```
export DATABASE_CLEANER_ALLOW_PRODUCTION=true
export DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL=true
```

In Ruby:

```ruby
DatabaseCleaner.allow_production = true
DatabaseCleaner.allow_remote_database_url = true
```

In Ruby, a URL allowlist can be specified. When specified, DatabaseCleaner will only allow `DATABASE_URL` to be equal
to one of the values specified in the url allowlist like so:

```ruby
DatabaseCleaner.url_allowlist = ['postgres://postgres@localhost', 'postgres://foo@bar']
```

Allowlist elements are matched with case equality (`===`), so regular expressions or procs may be used:

```ruby
DatabaseCleaner.url_allowlist = [
  %r{^postgres://postgres@localhost},         # match any db with this prefix
  proc {|uri| URI.parse(uri).user == "test" } # match any db authenticating with the 'test' user
]
```

## COPYRIGHT

See [LICENSE](LICENSE) for details.
