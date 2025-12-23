# pgvector-ruby

[pgvector](https://github.com/pgvector/pgvector) support for Ruby

Supports the [pg](https://github.com/ged/ruby-pg) gem

For Rails, check out [Neighbor](https://github.com/ankane/neighbor)

[![Build Status](https://github.com/pgvector/pgvector-ruby/workflows/build/badge.svg?branch=master)](https://github.com/pgvector/pgvector-ruby/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "pgvector"
```

And follow the instructions for your database library:

- [pg](#pg)

## pg

Register the vector type with your connection

```ruby
registry = PG::BasicTypeRegistry.new.define_default_types
Pgvector::PG.register_vector(registry)
conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn, registry: registry)
```

Insert a vector

```ruby
factors = [1, 2, 3]
conn.exec_params("INSERT INTO items (factors) VALUES ($1)", [factors])
```

Get the nearest neighbors to a vector

```ruby
conn.exec_params("SELECT * FROM items ORDER BY factors <-> $1 LIMIT 5", [factors]).to_a
```

## History

View the [changelog](https://github.com/pgvector/pgvector-ruby/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/pgvector/pgvector-ruby/issues)
- Fix bugs and [submit pull requests](https://github.com/pgvector/pgvector-ruby/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/pgvector/pgvector-ruby.git
cd pgvector-ruby
createdb pgvector_ruby_test
bundle install
bundle exec rake test
```
