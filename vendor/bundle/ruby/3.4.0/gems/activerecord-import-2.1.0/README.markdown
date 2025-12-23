# Activerecord-Import ![Build Status](https://github.com/zdennis/activerecord-import/actions/workflows/test.yaml/badge.svg)

Activerecord-Import is a library for bulk inserting data using ActiveRecord.

One of its major features is following activerecord associations and generating the minimal
number of SQL insert statements required, avoiding the N+1 insert problem. An example probably
explains it best. Say you had a schema like this:

- Publishers have Books
- Books have Reviews

and you wanted to bulk insert 100 new publishers with 10K books and 3 reviews per book. This library will follow the associations
down and generate only 3 SQL insert statements - one for the publishers, one for the books, and one for the reviews.

In contrast, the standard ActiveRecord save would generate
100 insert statements for the publishers, then it would visit each publisher and save all the books:
100 * 10,000 = 1,000,000 SQL insert statements
and then the reviews:
100 * 10,000 * 3 = 3M SQL insert statements,

That would be about 4M SQL insert statements vs 3, which results in vastly improved performance. In our case, it converted
an 18 hour batch process to <2 hrs.

The gem provides the following high-level features:

* Works with raw columns and arrays of values (fastest)
* Works with model objects (faster)
* Performs validations (fast)
* Performs on duplicate key updates (requires MySQL, SQLite 3.24.0+, or Postgres 9.5+)

## Table of Contents

* [Examples](#examples)
  * [Introduction](#introduction)
  * [Columns and Arrays](#columns-and-arrays)
  * [Hashes](#hashes)
  * [ActiveRecord Models](#activerecord-models)
  * [Batching](#batching)
  * [Recursive](#recursive)
* [Options](#options)
  * [Duplicate Key Ignore](#duplicate-key-ignore)
  * [Duplicate Key Update](#duplicate-key-update)
* [Return Info](#return-info)
* [Counter Cache](#counter-cache)
* [ActiveRecord Timestamps](#activerecord-timestamps)
* [Callbacks](#callbacks)
* [Supported Adapters](#supported-adapters)
* [Additional Adapters](#additional-adapters)
* [Requiring](#requiring)
  * [Autoloading via Bundler](#autoloading-via-bundler)
  * [Manually Loading](#manually-loading)
* [Load Path Setup](#load-path-setup)
* [Conflicts With Other Gems](#conflicts-with-other-gems)
* [More Information](#more-information)
* [Contributing](#contributing)
  * [Running Tests](#running-tests)
  * [Issue Triage](#issue-triage)

### Examples

#### Introduction

This gem adds an `import` method (or `bulk_import`, for compatibility with gems like `elasticsearch-model`; see [Conflicts With Other Gems](#conflicts-with-other-gems)) to ActiveRecord classes.

Without `activerecord-import`, you'd write something like this:

```ruby
10.times do |i|
  Book.create! name: "book #{i}"
end
```

This would end up making 10 SQL calls. YUCK!  With `activerecord-import`, you can instead do this:

```ruby
books = []
10.times do |i|
  books << Book.new(name: "book #{i}")
end
Book.import books    # or use import!
```

and only have 1 SQL call. Much better!

#### Columns and Arrays

The `import` method can take an array of column names (string or symbols) and an array of arrays. Each child array represents an individual record and its list of values in the same order as the columns. This is the fastest import mechanism and also the most primitive.

```ruby
columns = [ :title, :author ]
values = [ ['Book1', 'George Orwell'], ['Book2', 'Bob Jones'] ]

# Importing without model validations
Book.import columns, values, validate: false

# Import with model validations
Book.import columns, values, validate: true

# when not specified :validate defaults to true
Book.import columns, values
```

#### Hashes

The `import` method can take an array of hashes. The keys map to the column names in the database.

```ruby
values = [{ title: 'Book1', author: 'George Orwell' }, { title: 'Book2', author: 'Bob Jones'}]

# Importing without model validations
Book.import values, validate: false

# Import with model validations
Book.import values, validate: true

# when not specified :validate defaults to true
Book.import values
```
#### Import Using Hashes and Explicit Column Names

The `import` method can take an array of column names and an array of hash objects. The column names are used to determine what fields of data should be imported. The following example will only import books with the `title` field:

```ruby
books = [
  { title: "Book 1", author: "George Orwell" },
  { title: "Book 2", author: "Bob Jones" }
]
columns = [ :title ]

# without validations
Book.import columns, books, validate: false

# with validations
Book.import columns, books, validate: true

# when not specified :validate defaults to true
Book.import columns, books

# result in table books
# title  | author
#--------|--------
# Book 1 | NULL
# Book 2 | NULL

```

Using hashes will only work if the columns are consistent in every hash of the array. If this does not hold, an exception will be raised. There are two workarounds: use the array to instantiate an array of ActiveRecord objects and then pass that into `import` or divide the array into multiple ones with consistent columns and import each one separately.

See https://github.com/zdennis/activerecord-import/issues/507 for discussion.

```ruby
arr = [
  { bar: 'abc' },
  { baz: 'xyz' },
  { bar: '123', baz: '456' }
]

# An exception will be raised
Foo.import arr

# better
arr.map! { |args| Foo.new(args) }
Foo.import arr

# better
arr.group_by(&:keys).each_value do |v|
 Foo.import v
end
```

#### ActiveRecord Models

The `import` method can take an array of models. The attributes will be pulled off from each model by looking at the columns available on the model.

```ruby
books = [
  Book.new(title: "Book 1", author: "George Orwell"),
  Book.new(title: "Book 2", author: "Bob Jones")
]

# without validations
Book.import books, validate: false

# with validations
Book.import books, validate: true

# when not specified :validate defaults to true
Book.import books
```

The `import` method can take an array of column names and an array of models. The column names are used to determine what fields of data should be imported. The following example will only import books with the `title` field:

```ruby
books = [
  Book.new(title: "Book 1", author: "George Orwell"),
  Book.new(title: "Book 2", author: "Bob Jones")
]
columns = [ :title ]

# without validations
Book.import columns, books, validate: false

# with validations
Book.import columns, books, validate: true

# when not specified :validate defaults to true
Book.import columns, books

# result in table books
# title  | author
#--------|--------
# Book 1 | NULL
# Book 2 | NULL

```

#### Batching

The `import` method can take a `batch_size` option to control the number of rows to insert per INSERT statement. The default is the total number of records being inserted so there is a single INSERT statement.

```ruby
books = [
  Book.new(title: "Book 1", author: "George Orwell"),
  Book.new(title: "Book 2", author: "Bob Jones"),
  Book.new(title: "Book 1", author: "John Doe"),
  Book.new(title: "Book 2", author: "Richard Wright")
]
columns = [ :title ]

# 2 INSERT statements for 4 records
Book.import columns, books, batch_size: 2
```

If your import is particularly large or slow (possibly due to [callbacks](#callbacks)) whilst batch importing, you might want a way to report back on progress. This is supported by passing a callable as the `batch_progress` option. e.g:

```ruby
my_proc = ->(rows_size, num_batches, current_batch_number, batch_duration_in_secs) {
  # Using the arguments provided to the callable, you can
  # send an email, post to a websocket,
  # update slack, alert if import is taking too long, etc.
}

Book.import columns, books, batch_size: 2, batch_progress: my_proc
```

#### Recursive

> **Note**
> This only works with PostgreSQL and ActiveRecord objects. This won't work with hashes or arrays as recursive inputs.

Assume that Books <code>has_many</code> Reviews.

```ruby
books = []
10.times do |i|
  book = Book.new(name: "book #{i}")
  book.reviews.build(title: "Excellent")
  books << book
end
Book.import books, recursive: true
```

### Options

Key                       | Options               | Default            | Description
------------------------- | --------------------- | ------------------ | -----------
:validate                 | `true`/`false`        | `true`             | Whether or not to run `ActiveRecord` validations (uniqueness skipped). This option will always be true when using `import!`.
:validate_uniqueness      | `true`/`false`        | `false`            | Whether or not to run ActiveRecord uniqueness validations. Beware this will incur an sql query per-record (N+1 queries). (requires `>= v0.27.0`).
:validate_with_context    | `Symbol`              |`:create`/`:update` | Allows passing an ActiveModel validation context for each model. Default is `:create` for new records and `:update` for existing ones.
:track_validation_failures| `true`/`false`        | `false`            | When this is set to true, `failed_instances` will be an array of arrays, with each inner array having the form `[:index_in_dataset, :object_with_errors]`
:on_duplicate_key_ignore  | `true`/`false`        | `false`            | Allows skipping records with duplicate keys. See [here](#duplicate-key-ignore) for more details.
:ignore                   | `true`/`false`        | `false`            | Alias for :on_duplicate_key_ignore.
:on_duplicate_key_update  | :all, `Array`, `Hash` | N/A                | Allows upsert logic to be used. See [here](#duplicate-key-update) for more details.
:synchronize              | `Array`               | N/A                | An array of ActiveRecord instances. This synchronizes existing instances in memory with updates from the import.
:timestamps               | `true`/`false`        | `true`             | Enables/disables timestamps on imported records.
:recursive                | `true`/`false`        | `false`            | Imports has_many/has_one associations (PostgreSQL only).
:recursive_on_duplicate_key_update | `Hash`       | N/A                | Allows upsert logic to be used for recursive associations. The hash key is the association name and the value has the same options as `:on_duplicate_key_update`. See [here](#duplicate-key-update) for more details.
:batch_size               | `Integer`             | total # of records | Max number of records to insert per import
:raise_error              | `true`/`false`        | `false`            | Raises an exception at the first invalid record. This means there will not be a result object returned. The `import!` method is a shortcut for this.
:all_or_none              | `true`/`false`        | `false`            | Will not import any records if there is a record with validation errors.

#### Duplicate Key Ignore

[MySQL](http://dev.mysql.com/doc/refman/5.0/en/insert-on-duplicate.html), [SQLite](https://www.sqlite.org/lang_insert.html), and [PostgreSQL](https://www.postgresql.org/docs/current/static/sql-insert.html#SQL-ON-CONFLICT) (9.5+) support `on_duplicate_key_ignore` which allows you to skip records if a primary or unique key constraint is violated.

For Postgres 9.5+ it adds `ON CONFLICT DO NOTHING`, for MySQL it uses `INSERT IGNORE`, and for SQLite it uses `INSERT OR IGNORE`. Cannot be enabled on a recursive import. For database adapters that normally support setting primary keys on imported objects, this option prevents that from occurring.

```ruby
book = Book.create! title: "Book1", author: "George Orwell"
book.title = "Updated Book Title"
book.author = "Bob Barker"

Book.import [book], on_duplicate_key_ignore: true

book.reload.title  # => "Book1"     (stayed the same)
book.reload.author # => "George Orwell" (stayed the same)
```

The option `:on_duplicate_key_ignore` is bypassed when `:recursive` is enabled for [PostgreSQL imports](https://github.com/zdennis/activerecord-import/wiki#recursive-example-postgresql-only).

#### Duplicate Key Update

MySQL, PostgreSQL (9.5+), and SQLite (3.24.0+) support `on duplicate key update` (also known as "upsert") which allows you to specify fields whose values should be updated if a primary or unique key constraint is violated.

One big difference between MySQL and PostgreSQL support is that MySQL will handle any conflict that happens, but PostgreSQL requires that you specify which columns the conflict would occur over. SQLite models its upsert support after PostgreSQL.

This will use MySQL's `ON DUPLICATE KEY UPDATE` or Postgres/SQLite `ON CONFLICT DO UPDATE` to do upsert.

Basic Update

```ruby
book = Book.create! title: "Book1", author: "George Orwell"
book.title = "Updated Book Title"
book.author = "Bob Barker"

# MySQL version
Book.import [book], on_duplicate_key_update: [:title]

# PostgreSQL version
Book.import [book], on_duplicate_key_update: {conflict_target: [:id], columns: [:title]}

# PostgreSQL shorthand version (conflict target must be primary key)
Book.import [book], on_duplicate_key_update: [:title]

book.reload.title  # => "Updated Book Title" (changed)
book.reload.author # => "George Orwell"          (stayed the same)
```

Using the value from another column

```ruby
book = Book.create! title: "Book1", author: "George Orwell"
book.title = "Updated Book Title"

# MySQL version
Book.import [book], on_duplicate_key_update: {author: :title}

# PostgreSQL version (no shorthand version)
Book.import [book], on_duplicate_key_update: {
  conflict_target: [:id], columns: {author: :title}
}

book.reload.title  # => "Book1"              (stayed the same)
book.reload.author # => "Updated Book Title" (changed)
```

Using Custom SQL

```ruby
book = Book.create! title: "Book1", author: "George Orwell"
book.author = "Bob Barker"

# MySQL version
Book.import [book], on_duplicate_key_update: "author = values(author)"

# PostgreSQL version
Book.import [book], on_duplicate_key_update: {
  conflict_target: [:id], columns: "author = excluded.author"
}

# PostgreSQL shorthand version (conflict target must be primary key)
Book.import [book], on_duplicate_key_update: "author = excluded.author"

book.reload.title  # => "Book1"      (stayed the same)
book.reload.author # => "Bob Barker" (changed)
```

PostgreSQL Using partial indexes

```ruby
book = Book.create! title: "Book1", author: "George Orwell", published_at: Time.now
book.author = "Bob Barker"

# in migration
execute <<-SQL
      CREATE INDEX books_published_at_index ON books (published_at) WHERE published_at IS NOT NULL;
    SQL

# PostgreSQL version
Book.import [book], on_duplicate_key_update: {
  conflict_target: [:id],
  index_predicate: "published_at IS NOT NULL",
  columns: [:author]
}

book.reload.title  # => "Book1"          (stayed the same)
book.reload.author # => "Bob Barker"     (changed)
book.reload.published_at # => 2017-10-09 (stayed the same)
```

PostgreSQL Using constraints

```ruby
book = Book.create! title: "Book1", author: "George Orwell", edition: 3, published_at: nil
book.published_at = Time.now

# in migration
execute <<-SQL
      ALTER TABLE books
        ADD CONSTRAINT for_upsert UNIQUE (title, author, edition);
    SQL

# PostgreSQL version
Book.import [book], on_duplicate_key_update: {constraint_name: :for_upsert, columns: [:published_at]}


book.reload.title  # => "Book1"          (stayed the same)
book.reload.author # => "George Orwell"      (stayed the same)
book.reload.edition # => 3               (stayed the same)
book.reload.published_at # => 2017-10-09 (changed)
```

```ruby
Book.import books, validate_uniqueness: true
```

### Return Info

The `import` method returns a `Result` object that responds to `failed_instances` and `num_inserts`. Additionally, for users of Postgres, there will be two arrays `ids` and `results` that can be accessed.

```ruby
articles = [
  Article.new(author_id: 1, title: 'First Article', content: 'This is the first article'),
  Article.new(author_id: 2, title: 'Second Article', content: ''),
  Article.new(author_id: 3, content: '')
]

demo = Article.import(articles, returning: :title) # => #<struct ActiveRecord::Import::Result

demo.failed_instances
=> [#<Article id: 3, author_id: 3, title: nil, content: "", created_at: nil, updated_at: nil>]

demo.num_inserts
=> 1,

demo.ids
=> ["1", "2"] # for Postgres
=> [] # for other DBs

demo.results
=> ["First Article", "Second Article"] # for Postgres
=> [] # for other DBs
```

### Counter Cache

When running `import`, `activerecord-import` does not automatically update counter cache columns. To update these columns, you will need to do one of the following:

* Provide values to the column as an argument on your object that is passed in.
* Manually update the column after the record has been imported.

### ActiveRecord Timestamps

If you're familiar with ActiveRecord you're probably familiar with its timestamp columns: created_at, created_on, updated_at, updated_on, etc. When importing data the timestamp fields will continue to work as expected and each timestamp column will be set.

Should you wish to specify those columns, you may use the option `timestamps: false`.

However, it is also possible to set just `:created_at` in specific records. In this case despite using `timestamps: true`,  `:created_at` will be updated only in records where that field is `nil`. Same rule applies for record associations when enabling the option `recursive: true`.

If you are using custom time zones, these will be respected when performing imports as well as long as `ActiveRecord::Base.default_timezone` is set, which for practically all Rails apps it is.
> **Note**
> If you are using ActiveRecord 7.0 or later, please use `ActiveRecord.default_timezone` instead.

### Callbacks

ActiveRecord callbacks related to [creating](http://guides.rubyonrails.org/active_record_callbacks.html#creating-an-object), [updating](http://guides.rubyonrails.org/active_record_callbacks.html#updating-an-object), or [destroying](http://guides.rubyonrails.org/active_record_callbacks.html#destroying-an-object) records (other than `before_validation` and `after_validation`) will NOT be called when calling the import method. This is because it is mass importing rows of data and doesn't necessarily have access to in-memory ActiveRecord objects.

If you do have a collection of in-memory ActiveRecord objects you can do something like this:

```ruby
books.each do |book|
  book.run_callbacks(:save) { false }
  book.run_callbacks(:create) { false }
end
Book.import(books)
```

This will run before_create and before_save callbacks on each item. The `false` argument is needed to prevent after_save being run, which wouldn't make sense prior to bulk import. Something to note in this example is that the before_create and before_save callbacks will run before the validation callbacks.

If that is an issue, another possible approach is to loop through your models first to do validations and then only run callbacks on and import the valid models.

```ruby
valid_books = []
invalid_books = []

books.each do |book|
  if book.valid?
    valid_books << book
  else
    invalid_books << book
  end
end

valid_books.each do |book|
  book.run_callbacks(:save) { false }
  book.run_callbacks(:create) { false }
end

Book.import valid_books, validate: false
```

### Supported Adapters

The following database adapters are currently supported:

* MySQL - supports core import functionality plus on duplicate key update support (included in activerecord-import 0.1.0 and higher)
* MySQL2 - supports core import functionality plus on duplicate key update support (included in activerecord-import 0.2.0 and higher)
* PostgreSQL - supports core import functionality (included in activerecord-import 0.1.0 and higher)
* SQLite3 - supports core import functionality (included in activerecord-import 0.1.0 and higher)
* Oracle - supports core import functionality through DML trigger (available as an external gem: [activerecord-import-oracle_enhanced](https://github.com/keeguon/activerecord-import-oracle_enhanced)
* SQL Server - supports core import functionality (available as an external gem: [activerecord-import-sqlserver](https://github.com/keeguon/activerecord-import-sqlserver)

If your adapter isn't listed here, please consider creating an external gem as described in the README to provide support. If you do, feel free to update this wiki to include a link to the new adapter's repository!

To test which features are supported by your adapter, use the following methods on a model class:
* `supports_import?(*args)`
* `supports_on_duplicate_key_update?`
* `supports_setting_primary_key_of_imported_objects?`

### Additional Adapters

Additional adapters can be provided by gems external to activerecord-import by providing an adapter that matches the naming convention setup by activerecord-import (and subsequently activerecord) for dynamically loading adapters.  This involves also providing a folder on the load path that follows the activerecord-import naming convention to allow activerecord-import to dynamically load the file.

When `ActiveRecord::Import.require_adapter("fake_name")` is called the require will be:

```ruby
require 'activerecord-import/active_record/adapters/fake_name_adapter'
```

This allows an external gem to dynamically add an adapter without the need to add any file/code to the core activerecord-import gem.

### Requiring

> **Note**
> These instructions will only work if you are using version 0.2.0 or higher.

#### Autoloading via Bundler

If you are using Rails or otherwise autoload your dependencies via Bundler, all you need to do add the gem to your `Gemfile` like so:

```ruby
gem 'activerecord-import'
```

#### Manually Loading

You may want to manually load activerecord-import for one reason or another. First, add the `require: false` argument like so:

```ruby
gem 'activerecord-import', require: false
```

This will allow you to load up activerecord-import in the file or files where you are using it and only load the parts you need.
If you are doing this within Rails and ActiveRecord has established a database connection (such as within a controller), you will need to do extra initialization work:

```ruby
require 'activerecord-import/base'
# load the appropriate database adapter (postgresql, mysql2, sqlite3, etc)
require 'activerecord-import/active_record/adapters/postgresql_adapter'
```

If your gem dependencies aren’t autoloaded, and your script will be establishing a database connection, then simply require activerecord-import after ActiveRecord has been loaded, i.e.:

```ruby
require 'active_record'
require 'activerecord-import'
```

### Load Path Setup
To understand how rubygems loads code you can reference the following:

  https://guides.rubygems.org/patterns/#loading-code

And an example of how active_record dynamically load adapters:

  https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters.rb

In summary, when a gem is loaded rubygems adds the `lib` folder of the gem to the global load path `$LOAD_PATH` so that all `require` lookups will not propagate through all of the folders on the load path. When a `require` is issued each folder on the `$LOAD_PATH` is checked for the file and/or folder referenced. This allows a gem (like activerecord-import) to define push the activerecord-import folder (or namespace) on the `$LOAD_PATH` and any adapters provided by activerecord-import will be found by rubygems when the require is issued.

If `fake_name` adapter is needed by a gem (potentially called `activerecord-import-fake_name`) then the folder structure should look as follows:

```bash
activerecord-import-fake_name/
|-- activerecord-import-fake_name.gemspec
|-- lib
|   |-- activerecord-import-fake_name.rb
|   |-- activerecord-import-fake_name
|   |   |-- version.rb
|   |-- activerecord-import
|   |   |-- active_record
|   |   |   |-- adapters
|   |   |       |-- fake_name_adapter.rb
```

When rubygems pushes the `lib` folder onto the load path a `require` will now find `activerecord-import/active_record/adapters/fake_name_adapter` as it runs through the lookup process for a ruby file under that path in `$LOAD_PATH`


### Conflicts With Other Gems

Activerecord-Import adds the `.import` method onto `ActiveRecord::Base`. There are other gems, such as `elasticsearch-rails`, that do the same thing. In conflicts such as this, there is an aliased method named `.bulk_import` that can be used interchangeably.

If you are using the `apartment` gem, there is a weird triple interaction between that gem, `activerecord-import`, and `activerecord` involving caching of the `sequence_name` of a model. This can be worked around by explicitly setting this value within the model. For example:

```ruby
class Post < ActiveRecord::Base
  self.sequence_name = "posts_seq"
end
```

Another way to work around the issue is to call `.reset_sequence_name` on the model. For example:

```ruby
schemas.all.each do |schema|
  Apartment::Tenant.switch! schema.name
  ActiveRecord::Base.transaction do
    Post.reset_sequence_name

    Post.import posts
  end
end
```

See https://github.com/zdennis/activerecord-import/issues/233 for further discussion.

### More Information

For more information on Activerecord-Import please see its wiki: https://github.com/zdennis/activerecord-import/wiki

To document new information, please add to the README instead of the wiki. See https://github.com/zdennis/activerecord-import/issues/397 for discussion.

### Contributing

#### Running Tests

The first thing you need to do is set up your database(s):

* copy `test/database.yml.sample` to `test/database.yml`
* modify `test/database.yml` for your database settings
* create databases as needed

After that, you can run the tests. They run against multiple tests and ActiveRecord versions.

This is one example of how to run the tests:

```bash
rm Gemfile.lock
AR_VERSION=7.0 bundle install
AR_VERSION=7.0 bundle exec rake test:postgresql test:sqlite3 test:mysql2
```

Once you have pushed up your changes, you can find your CI results [here](https://github.com/zdennis/activerecord-import/actions).

#### Docker Setup

Before you begin, make sure you have [Docker](https://www.docker.com/products/docker-desktop/) and [Docker Compose](https://docs.docker.com/compose/) installed on your machine. If you don't, you can install both via Homebrew using the following command:

```bash
brew install docker && brew install docker-compose
```
##### Steps

1. In your terminal run `docker-compose up --build`
1. In another tab/window run `docker-compose exec app bash`
1. In that same terminal run the mysql2 test by running `bundle exec rake test:mysql2`

## Issue Triage [![Open Source Helpers](https://www.codetriage.com/zdennis/activerecord-import/badges/users.svg)](https://www.codetriage.com/zdennis/activerecord-import)

You can triage issues which may include reproducing bug reports or asking for vital information, such as version numbers or reproduction instructions. If you would like to start triaging issues, one easy way to get started is to [subscribe to activerecord-import on CodeTriage](https://www.codetriage.com/zdennis/activerecord-import).

# License

This is licensed under the MIT license.

# Author

Zach Dennis (zach.dennis@gmail.com)
