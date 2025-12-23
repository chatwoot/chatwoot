# MiniMime

Minimal mime type implementation for use with the mail and rest-client gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mini_mime'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mini_mime

## Usage

```
require 'mini_mime'

MiniMime.lookup_by_filename("a.txt").content_type
# => "text/plain"

MiniMime.lookup_by_extension("txt").content_type
# => "text/plain"

MiniMime.lookup_by_content_type("text/plain").extension
# => "txt"

MiniMime.lookup_by_content_type("text/plain").binary?
# => false

```

## Configuration

If you'd like to add your own mime types, try using custom database files:

```
MiniMime::Configuration.ext_db_path = "path_to_file_extension_db"
MiniMime::Configuration.content_type_db_path = "path_to_content_type_db"
```

Check out the [default databases](lib/db) for proper formatting and structure hints.

## Performance

MiniMime is optimised to minimize memory usage. It keeps a cache of 100 mime type lookups (and 100 misses). There are benchmarks in the [bench directory](https://github.com/discourse/mini_mime/blob/master/bench/bench.rb)

```
Memory stats for requiring mime/types/columnar
Total allocated: 8712144 bytes (98242 objects)
Total retained:  3372545 bytes (33599 objects)

Memory stats for requiring mini_mime
Total allocated: 42625 bytes (369 objects)
Total retained:  8992 bytes (72 objects)
Warming up --------------------------------------
cached content_type lookup MiniMime
                        85.109k i/100ms
content_type lookup MIME::Types
                        17.879k i/100ms
Calculating -------------------------------------
cached content_type lookup MiniMime
                          1.105M (± 4.1%) i/s -      5.532M in   5.014895s
content_type lookup MIME::Types
                        193.528k (± 7.1%) i/s -    965.466k in   5.013925s
Warming up --------------------------------------
uncached content_type lookup MiniMime
                         1.410k i/100ms
content_type lookup MIME::Types
                        18.012k i/100ms
Calculating -------------------------------------
uncached content_type lookup MiniMime
                         14.689k (± 4.2%) i/s -     73.320k in   5.000779s
content_type lookup MIME::Types
                        193.459k (± 6.9%) i/s -    972.648k in   5.050731s
```

As a general guideline, cached lookups are 6x faster than MIME::Types equivalent. Uncached lookups are 10x slower.

Note: It was run on macOS 10.14.2, and versions of Ruby and gems are below.

- Ruby 2.6.0
- mini_mime (1.0.1)
- mime-types (3.2.2)
- mime-types-data (3.2018.0812)

## Development

MiniMime uses the officially maintained list of mime types at [mime-types-data](https://github.com/mime-types/mime-types-data) repo to build the internal database.

To update the database run:

```ruby
bundle exec rake rebuild_db
```

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/discourse/mini_mime. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
