# Database Cleaner Adapter for ActiveRecord

[![Tests](https://github.com/DatabaseCleaner/database_cleaner-active_record/actions/workflows/ci.yml/badge.svg)](https://github.com/DatabaseCleaner/database_cleaner-active_record/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/DatabaseCleaner/database_cleaner-active_record/badges/gpa.svg)](https://codeclimate.com/github/DatabaseCleaner/database_cleaner-active_record)
[![codecov](https://codecov.io/gh/DatabaseCleaner/database_cleaner-active_record/branch/master/graph/badge.svg)](https://codecov.io/gh/DatabaseCleaner/database_cleaner-active_record)

Clean your ActiveRecord databases with Database Cleaner.

See https://github.com/DatabaseCleaner/database_cleaner for more information.

For support or to discuss development please use the [Google Group](https://groups.google.com/group/database_cleaner).

## Installation

```ruby
# Gemfile
group :test do
  gem 'database_cleaner-active_record'
end
```

## Supported Strategies

Three strategies are supported:

* Transaction (default)
* Truncation
* Deletion

## What strategy is fastest?

For the SQL libraries the fastest option will be to use `:transaction` as transactions are simply rolled back. If you can use this strategy you should. However, if you wind up needing to use multiple database connections in your tests (i.e. your tests run in a different process than your application) then using this strategy becomes a bit more difficult. You can get around the problem a number of ways.

One common approach is to force all processes to use the same database connection ([common ActiveRecord hack](http://blog.plataformatec.com.br/2011/12/three-tips-to-improve-the-performance-of-your-test-suite/)) however this approach has been reported to result in non-deterministic failures.

Another approach is to have the transactions rolled back in the application's process and relax the isolation level of the database (so the tests can read the uncommitted transactions).

An easier, but slower, solution is to use the `:truncation` or `:deletion` strategy.

So what is fastest out of `:deletion` and `:truncation`? Well, it depends on your table structure and what percentage of tables you populate in an average test. The reasoning is out of the scope of this README but here is a [good SO answer on this topic for Postgres](https://stackoverflow.com/questions/11419536/postgresql-truncation-speed/11423886#11423886).

Some people report much faster speeds with `:deletion` while others say `:truncation` is faster for them. The best approach therefore is it try all options on your test suite and see what is faster.

## Strategy configuration options

The transaction strategy accepts no options.

The truncation and deletion strategies may accept the following options:

* `:only` and `:except` may take a list of table names:

```ruby
# Only truncate the "users" table.
DatabaseCleaner[:active_record].strategy = DatabaseCleaner::ActiveRecord::Truncation.new(only: ["users"])

# Delete all tables except the "users" table.
DatabaseCleaner[:active_record].strategy = DatabaseCleaner::ActiveRecord::Deletion.new(except: ["users"])
```

* `:pre_count` - When set to `true` this will check each table for existing rows before truncating or deleting it.  This can speed up test suites when many of the tables are never populated. Defaults to `false`. (Also, see the section on [What strategy is fastest?](#what-strategy-is-fastest))

* `:cache_tables` - When set to `true` the list of tables to truncate or delete from will only be read from the DB once, otherwise it will be read before each cleanup run. Set this to `false` if (1) you create and drop tables in your tests, or (2) you change Postgres schemas (`ActiveRecord::Base.connection.schema_search_path`) in your tests (for example, in a multitenancy setup with each tenant in a different Postgres schema). Defaults to `true`.

## Adapter configuration options

`#db` defaults to the default ActiveRecord database, but can be specified manually in a few ways:

```ruby
# ActiveRecord connection key
DatabaseCleaner[:active_record].db = :logs

# Back to default:
DatabaseCleaner[:active_record].db = :default

# Multiple databases can be specified:
DatabaseCleaner[:active_record, db: :default]
DatabaseCleaner[:active_record, db: :logs]
```

## Common Errors

### STDERR is being flooded when using Postgres

If you are using Postgres and have foreign key constraints, the truncation strategy will cause a lot of extra noise to appear on STDERR (in the form of "NOTICE truncate cascades" messages).

To silence these warnings set the following log level in your `postgresql.conf` file:

```
client_min_messages = warning
```

You can also add this parameter to your database.yml file:

<pre>
test:
  adapter: postgresql
  # ...
  min_messages: WARNING  
</pre>

## COPYRIGHT

See [LICENSE](LICENSE) for details.
