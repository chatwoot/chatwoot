## AnnotateRb

### forked from the [Annotate aka AnnotateModels gem](https://github.com/ctran/annotate_models)

A Ruby Gem that adds annotations to your Rails models and route files.

---

[![CI](https://github.com/drwl/annotaterb/actions/workflows/ci.yml/badge.svg)](https://github.com/drwl/annotaterb/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/annotaterb.svg)](https://badge.fury.io/rb/annotaterb)

Adds comments summarizing the model schema or routes in your:

- ActiveRecord models
- Fixture files
- Tests and Specs
- FactoryBot factories
- `routes.rb` file (for Rails projects)

The schema comment looks like this:

```ruby
# == Schema Information
#
# Table name: tasks
#
#  id         :integer          not null, primary key
#  content    :string
#  count      :integer
#  status     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Task < ApplicationRecord
  ...
```

---

## Installation

```sh
$ gem install annotaterb
```

Or install it into your Rails project through the Gemfile:

```rb
group :development do
  ...

  gem "annotaterb"

  ...
```

### Automatically annotate models

For Rails projects, model files can get automatically annotated after migration tasks. To do this, run the following command:

```sh
$ bin/rails g annotate_rb:install
```

This will copy a rake task into your Rails project's `lib/tasks` directory that will hook into the Rails project rake tasks, automatically running AnnotateRb after database migration rake tasks.

To skip the automatic annotation that happens after a db task, pass the environment variable `ANNOTATERB_SKIP_ON_DB_TASKS=1` before your command.

```sh
$ ANNOTATERB_SKIP_ON_DB_TASKS=1 bin/rails db:migrate
```

### Added Rails generators

The following Rails generator commands get added.

```sh
$ bin/rails generator --help

...

AnnotateRb:
  annotate_rb:config
  annotate_rb:hook
  annotate_rb:install
  annotate_rb:update_config
...

```

`bin/rails g annotate_rb:config`

- Generates a new configuration file, `.annotaterb.yml`, using defaults from the gem.

`bin/rails g annotate_rb:hook`

- Installs the Rake file to automatically annotate Rails models on a database task (e.g. AnnotateRb will automatically run after running `bin/rails db:migrate`).

`bin/rails g annotate_rb:install`

- Runs the `config` and `hook` generator commands

`bin/rails g annotate_rb:update_config`

- Appends to `.annotaterb.yml` any configuration key-value pairs that are used by the Gem. This is useful when there's a drift between the config file values and the gem defaults (i.e. when new features get added).

## Migrating from the annotate gem

Refer to the [migration guide](MIGRATION_GUIDE.md).

## Usage

AnnotateRb has a CLI that you can use to add or remove annotations.

```sh
# To show the CLI options
$ bundle exec annotaterb

Usage: annotaterb [command] [options]

Commands:
    models [options]
    routes [options]
    help
    version

Options:
    -v, --version                    Display the version..
    -h, --help                       You're looking at it.

Annotate model options:
    Usage: annotaterb models [options]

    -a, --active-admin               Annotate active_admin models
        --show-migration             Include the migration version number in the annotation
    -k, --show-foreign-keys          List the table's foreign key constraints in the annotation
        --ck, --complete-foreign-keys
                                     Complete foreign key names in the annotation
    -i, --show-indexes               List the table's database indexes in the annotation
    -s, --simple-indexes             Concat the column's related indexes in the annotation
    -c, --show-check-constraints     List the table's check constraints in the annotation
        --hide-limit-column-types VALUES
                                     don't show limit for given column types, separated by commas (i.e., `integer,boolean,text`)
        --hide-default-column-types VALUES
                                     don't show default for given column types, separated by commas (i.e., `json,jsonb,hstore`)
        --ignore-unknown-models      don't display warnings for bad model files
    -I, --ignore-columns REGEX       don't annotate columns that match a given REGEX (i.e., `annotate -I '^(id|updated_at|created_at)'`
        --with-comment               include database comments in model annotations
        --without-comment            exclude database comments in model annotations
        --with-column-comments       include column comments in model annotations
        --without-column-comments    exclude column comments in model annotations
        --position-of-column-comment [with_name|rightmost_column]
                                     set the position, in the annotation block, of the column comment
        --with-table-comments        include table comments in model annotations
        --without-table-comments     exclude table comments in model annotations
        --classes-default-to-s class Custom classes to be represented with `to_s`, may be used multiple times
        --nested-position            Place annotations directly above nested classes or modules instead of at the top of the file.

Annotate routes options:
    Usage: annotaterb routes [options]

        --ignore-routes REGEX        don't annotate routes that match a given REGEX (i.e., `annotate -I '(mobile|resque|pghero)'`
        --timestamp                  Include timestamp in (routes) annotation
        --w, --wrapper STR           Wrap annotation with the text passed as parameter.
                                     If --w option is used, the same text will be used as opening and closing
        --wo, --wrapper-open STR     Annotation wrapper opening.
        --wc, --wrapper-close STR    Annotation wrapper closing

Command options:
Additional options that work for annotating models and routes

        --additional-file-patterns path1,path2,path3
                                     Additional file paths or globs to annotate, separated by commas (e.g. `/foo/bar/%MODEL_NAME%/*.rb,/baz/%MODEL_NAME%.rb`)
    -d, --delete                     Remove annotations from all model files or the routes.rb file
        --model-dir dir              Annotate model files stored in dir rather than app/models, separate multiple dirs with commas
        --root-dir dir               Annotate files stored within root dir projects, separate multiple dirs with commas
        --ignore-model-subdirects    Ignore subdirectories of the models directory
        --sort                       Sort columns alphabetically, rather than in creation order
        --classified-sort            Sort columns alphabetically, but first goes id, then the rest columns, then the timestamp columns and then the association columns
        --grouped-polymorphic        Group polymorphic associations together in the annotation when using --classified-sort
    -R, --require path               Additional file to require before loading models, may be used multiple times
    -e [tests,fixtures,factories,serializers],
        --exclude                    Do not annotate fixtures, test files, factories, and/or serializers
    -f [bare|rdoc|yard|markdown],    Render Schema Information as plain/RDoc/Yard/Markdown
        --format
    -p [before|top|after|bottom],    Place the annotations at the top (before) or the bottom (after) of the model/test/fixture/factory/route/serializer file(s)
        --position
        --pc, --position-in-class [before|top|after|bottom]
                                     Place the annotations at the top (before) or the bottom (after) of the model file
        --pf, --position-in-factory [before|top|after|bottom]
                                     Place the annotations at the top (before) or the bottom (after) of any factory files
        --px, --position-in-fixture [before|top|after|bottom]
                                     Place the annotations at the top (before) or the bottom (after) of any fixture files
        --pt, --position-in-test [before|top|after|bottom]
                                     Place the annotations at the top (before) or the bottom (after) of any test files
        --pr, --position-in-routes [before|top|after|bottom]
                                     Place the annotations at the top (before) or the bottom (after) of the routes.rb file
        --ps, --position-in-serializer [before|top|after|bottom]
                                     Place the annotations at the top (before) or the bottom (after) of the serializer files
        --pa, --position-in-additional-file-patterns [before|top|after|bottom]
                                     Place the annotations at the top (before) or the bottom (after) of files captured in additional file patterns
        --force                      Force new annotations even if there are no changes.
        --debug                      Prints the options and outputs messages to make it easier to debug.
        --frozen                     Do not allow to change annotations. Exits non-zero if there are going to be changes to files.
        --trace                      If unable to annotate a file, print the full stack trace, not just the exception message.
```

## Configuration

### Storing default options

Previously in the [Annotate](https://github.com/ctran/annotate_models) you could pass options through the CLI or store them as environment variables. Annotaterb removes dependency on the environment variables and instead can read values from a `.annotaterb.yml` file stored in the Rails project root.

```yml
# .annotaterb.yml

position: after
```

Annotaterb reads first the configuration file, if it exists, passes its content through ERB, and merges the result with any options passed into the CLI.

For further details visit the [section in the migration guide](MIGRATION_GUIDE.md#automatic-annotations-after-running-database-migration-commands).

### How to skip annotating a particular model

If you want to always skip annotations on a particular model, add this string
anywhere in the file:

    # -*- SkipSchemaAnnotations

## Sorting

By default, columns will be sorted in database order (i.e. the order in which
migrations were run).

If you prefer to sort alphabetically so that the results of annotation are
consistent regardless of what order migrations are executed in, use `--sort`.

You can also sort columns by type, then alphabetically using `--classified-sort`
and `--grouped-polymorphic`: first goes id, then the rest columns, then the
timestamp columns and then the association columns.

## License

Released under the same license as Ruby. No Support. No Warranty.
