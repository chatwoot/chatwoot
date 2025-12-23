# HairTrigger
[<img src="https://github.com/jenseng/hair_trigger/workflows/CI/badge.svg" />](https://github.com/jenseng/hair_trigger/actions?query=workflow%3ACI)

HairTrigger lets you create and manage database triggers in a concise,
db-agnostic, Rails-y way. You declare triggers right in your models in Ruby,
and a simple rake task does all the dirty work for you.

## Installation

HairTrigger works with Rails 5.0 onwards. Add the following line to your Gemfile:

```ruby
gem 'hairtrigger'
```

Then run `bundle install`

For older versions of Rails check the last [0.2 release](https://github.com/jenseng/hair_trigger/tree/v0.2.21)

## Usage

### Models

Declare triggers in your models and use a rake task to auto-generate the
appropriate migration. For example:

```ruby
class AccountUser < ActiveRecord::Base
  trigger.after(:insert) do
    "UPDATE accounts SET user_count = user_count + 1 WHERE id = NEW.account_id;"
  end

  trigger.after(:update).of(:name) do
    "INSERT INTO user_changes(id, name) VALUES(NEW.id, NEW.name);"
  end
end
```

and then:

```bash
rake db:generate_trigger_migration
```

This will create a db-agnostic migration for the trigger that mirrors the
model declaration. The end result in MySQL will be something like this:

```sql
CREATE TRIGGER account_users_after_insert_row_tr AFTER INSERT ON account_users
FOR EACH ROW
BEGIN
    UPDATE accounts SET user_count = user_count + 1 WHERE id = NEW.account_id;
END;

CREATE TRIGGER account_users_after_update_on_name_row_tr AFTER UPDATE ON account_users
FOR EACH ROW
BEGIN
    IF NEW.name <> OLD.name OR (NEW.name IS NULL) <> (OLD.name IS NULL) THEN
        INSERT INTO user_changes(id, name) VALUES(NEW.id, NEW.name);
    END IF;
END;
```

Note that these auto-generated `create_trigger` statements in the migration
contain the `:generated => true` option, indicating that they were created
from the model definition. This is important, as the rake task will also
generate appropriate drop/create statements for any model triggers that get
removed or updated. It does this by diffing the current model trigger
declarations and any auto-generated triggers in schema.rb (and subsequent
migrations).

### Chainable Methods

Triggers are built by chaining several methods together, ending in a block
that specifies the SQL to be run when the trigger fires. Supported methods
include:

#### name(trigger_name)
Optional, inferred from other calls.

#### on(table_name)
Ignored in models, required in migrations.

#### for_each(item)
Defaults to `:row`, PostgreSQL allows `:statement`.

#### before(*events)
Shorthand for `timing(:before).events(*events)`.

#### after(*events)
Shorthand for `timing(:after).events(*events)`.

#### where(conditions)
Optional, SQL snippet limiting when the trigger will fire. Supports delayed interpolation of variables.

#### of(*columns)

Only fire the update trigger if at least one of the columns is specified in the statement. Platforms that support it use a native `OF` clause, others will have an inferred `IF ...` statement in the trigger body. Note the former will fire even if the column's value hasn't changed; the latter will not.

#### security(user)
Permissions/role to check when calling trigger. PostgreSQL supports `:invoker` (default) and `:definer`, MySQL supports `:definer` (default) and arbitrary users (syntax: `'user'@'host'`).

#### timing(timing)
Required (but may be satisfied by `before`/`after`). Possible values are `:before`/`:after`.

#### events(*events)
Required (but may be satisfied by `before`/`after`). Possible values are `:insert`/`:update`/`:delete`/`:truncate`. MySQL/SQLite only support one action per trigger, and don't support `:truncate`.

#### nowrap(flag = true)
PostgreSQL-specific option to prevent the trigger action from being wrapped in a `CREATE FUNCTION`. This is useful for executing existing triggers/functions directly, but is not compatible with the `security` setting nor can it be used with pre-9.0 PostgreSQL when supplying a `where` condition.

Example: `trigger.after(:update).nowrap { "tsvector_update_trigger(...)" }`

#### declare
PostgreSQL-specific option for declaring variables for use in the
trigger function. Declarations should be separated by semicolons, e.g.

```ruby
trigger.after(:insert).declare("user_type text; status text") do
  <<-SQL
    IF (NEW.account_id = 1 OR NEW.email LIKE '%company.com') THEN
      user_type := 'employee';
    ELSIF ...
  SQL
end
```

#### all
Noop, useful for trigger groups (see below).

### Trigger Groups

Trigger groups allow you to use a slightly more concise notation if you have
several triggers that fire on a given model. This is also important for MySQL,
since it does not support multiple triggers on a table for the same action
and timing. For example:

```ruby
trigger.after(:update) do |t|
  t.all do # every row
    # some sql
  end
  t.of("foo") do
    # some more sql
  end
  t.where("OLD.bar != NEW.bar AND NEW.bar != 'lol'") do
    # some other sql
  end
end
```

For MySQL, this will just create a single trigger with conditional logic
(since it doesn't support multiple triggers). PostgreSQL and SQLite will have
distinct triggers. This same notation is also used within trigger migrations.
MySQL does not currently support nested trigger groups.

Because of these differences in how the triggers are created, take care
when setting the `name` for triggers or groups. In other words,
PostgreSQL/SQLite will use the `name`s specified on the individual
triggers; MySQL will use the `name` specified on the group.

### Database-specific trigger bodies

Although HairTrigger aims to be totally db-agnostic, at times you do need a
little more control over the body of the trigger. You can tailor it for
specific databases by returning a hash rather than a string. Make sure to set
a `:default` value if you aren't explicitly specifying all of them.

For example, MySQL generally performs poorly with subselects in `UPDATE`
statements, and it has its own proprietary syntax for multi-table `UPDATE`s. So
you might do something like the following:

```ruby
trigger.after(:insert) do
  {:default => <<-DEFAULT_SQL, :mysql => <<-MYSQL}

  UPDATE users SET item_count = item_count + 1
  WHERE id IN (SELECT user_id FROM buckets WHERE id = NEW.bucket_id)
  DEFAULT_SQL

  UPDATE users, buckets SET item_count = item_count + 1
  WHERE users.id = user_id AND buckets.id = NEW.bucket_id
  MYSQL
end
```

### Manual Migrations

You can also manage triggers manually in your migrations via `create_trigger` and
`drop_trigger`. They are a little more verbose than model triggers, and they can
be more work since you need to figure out the up/down create/drop logic when
you change things. A sample trigger:

```ruby
create_trigger(:compatibility => 1).on(:users).after(:insert) do
  "UPDATE accounts SET user_count = user_count + 1 WHERE id = NEW.account_id;"
end
```

Because `create_trigger` may drop an existing trigger of the same name,
you need to actually implement `up`/`down` methods in your migration
(rather than `change`) so that it does the right thing when
rolling back.

#### Manual triggers and :compatibility

As bugs are fixed and features are implemented in HairTrigger, it's possible
that the generated trigger SQL will change (this has only happened once so
far). If you upgrade to a newer version of HairTrigger, it needs a way of
knowing which previous version generated the original trigger. You only need
to worry about this for manual trigger migrations, as the model ones
automatically take care of this. For your manual triggers you can either:

* pass `:compatibility => x` to your `create_trigger` statement, where x is
  whatever HairTrigger::Builder.compatibility is (1 for this version).
* set `HairTrigger::Builder.base_compatibility = x` in an initializer, where
  x is whatever HairTrigger::Builder.compatibility is. This is like doing the
  first option on every `create_trigger`. Note that once the compatibility
  changes, you'll need to set `:compatibility` on new triggers (unless you
  just redo all your triggers and bump the `base_compatibility`).

If you upgrade to a newer version of HairTrigger and see that the SQL
compatibility has changed, you'll need to set the appropriate compatibility
on any new triggers that you create.

## rake db:schema:dump

HairTrigger hooks into `rake db:schema:dump` (and rake tasks that call it) to
make it trigger-aware. A newly generated schema.rb will contain:

* `create_trigger` statements for any database triggers that exactly match a
  `create_trigger` statement in an applied migration or in the previous
  schema.rb file. this includes both generated and manual `create_trigger`
  calls.
* adapter-specific `execute('CREATE TRIGGER..')` statements for any unmatched
  database triggers.

As long as you don't delete old migrations and schema.rb prior to running
`rake db:schema:dump`, the result should be what you expect (and portable).
If you have deleted all trigger migrations, you can regenerate a new
baseline for model triggers via `rake db:generate_trigger_migration`.

### Filtering

It is possible to filter which triggers are dumped by setting any of these
configuration values:

```ruby
HairTrigger::SchemaDumper::Configuration.ignore_triggers = 'exact_trigger_name'
HairTrigger::SchemaDumper::Configuration.ignore_tables = [/partial_/, 'exact_table_name']
HairTrigger::SchemaDumper::Configuration.allow_triggers = [/partial_/, 'exact_trigger_name']
HairTrigger::SchemaDumper::Configuration.allow_tables = 'exact_table_name'
```

Each option can accept a single String or Regexp, or a mixed array of both.


## Testing

To stay on top of things, it's strongly recommended that you add a test or
spec to ensure your migrations/schema.rb match your models. This is as simple
as:

```ruby
assert HairTrigger::migrations_current?
```

This way you'll know if there are any outstanding migrations you need to
create.

## Warnings and Errors

There are a couple classes of errors: declaration errors and generation
errors/warnings.

Declaration errors happen if your trigger declaration is obviously wrong, and
will cause a runtime error in your model or migration class. An example would
be `trigger.after(:never)`, since `:never` is not a valid event.

Generation errors happen if you try something that your adapter doesn't
support. An example would be something like `trigger.security(:invoker)` for
MySQL. These errors only happen when the trigger is actually generated, e.g.
when you attempt to run the migration.

Generation warnings are similar but they don't stop the trigger from being
generated. If you do something adapter-specific supported by your database,
you will still get a warning (to $stderr) that your trigger is not portable. You
can silence warnings via `HairTrigger::Builder.show_warnings = false`

You can validate your triggers beforehand using the `Builder#validate!` method.
It will throw the appropriate errors/warnings so that you know what to fix,
e.g.

```ruby
User.triggers.each(&:validate!)
```

HairTrigger does not validate your SQL, so be sure to test it in all databases
you want to support.

### PostgreSQL NOTICEs

When running a trigger migration, you might notice some PostgreSQL
NOTICEs like so:

```
NOTICE:  trigger "foo_bar_baz" for table "quux" does not exist, skipping
NOTICE:  function foo_bar_baz() does not exist, skipping
```

This happens because HairTrigger will attempt to drop the existing
trigger/function if it already exists. These notices are safe to
ignore. Note that this behavior [may change](https://github.com/jenseng/hair_trigger/issues/28)
in a future release, meaning you'll first need to explicitly drop the
existing trigger if you wish to redefine it.

## Gotchas

* As is the case with `ActiveRecord::Base.update_all` or any direct SQL you do,
  be careful to reload updated objects from the database. For example, the
  following code will display the wrong count since we aren't reloading the
  account:

  ```ruby
  a = Account.find(123)
  a.account_users.create(:name => 'bob')
  puts "count is now #{a.user_count}"
  ```
* For repeated chained calls, the last one wins, there is currently no
  merging.
* If you want your code to be portable, the trigger actions should be
  limited to `INSERT`/`UPDATE`/`DELETE`/`SELECT`, and conditional logic should be
  handled through the `:where` option/method. Otherwise you'll likely run into
  trouble due to differences in syntax and supported features.
* Manual `create_trigger` statements have some gotchas. See the section
  "Manual triggers and :compatibility"

## Contributing

Contributions welcome! I don't write much Ruby these days 😢 (and haven't used this
gem in years 😬) but am happy to take contributions. If I'm slow to respond, don't
hesitate to @ me repeatedly, sometimes those github notifications slip through
the cracks. 😆.

If you want to add a feature/bugfix, you can rely on Github Actions to run the
tests, but do also run them locally (especially if you are changing supported
railses/etc). HairTrigger uses [appraisal](https://github.com/thoughtbot/appraisal)
to manage all that w/ automagical gemfiles. So the tl;dr when testing locally is:

1. make sure you have mysql and postgres installed (homebrew or whatever)
2. `bundle exec appraisal install` -- get all the dependencies
3. `bundle exec appraisal rake` -- run the specs every which way

## Compatibility

* Ruby 2.3.0+
* Rails 5.0+
* PostgreSQL 8.0+
* MySQL 5.0.10+
* SQLite 3.3.8+

## [Changelog](CHANGELOG.md)

## Copyright

Copyright (c) 2011-2022 Jon Jensen. See LICENSE.txt for further details.
