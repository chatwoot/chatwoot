# MetaRequest

Supporting gem for [Rails Panel (Google Chrome extension for Rails development)](https://github.com/dejan/rails_panel).

## Installation

Add meta_request gem to development group in Gemfile:

```ruby
group :development do
  gem 'meta_request'
end
```

## Usage

See [Rails Panel extension](https://github.com/dejan/rails_panel).

## Compatibility Warnings

If you're using [LiveReload](http://livereload.com/) or
[Rack::LiveReload](https://github.com/johnbintz/rack-livereload) make sure to
exclude watching your tmp/ folder because meta_request writes a lot of data there
and your browser will refresh like a madman.

## Configuration

Gem can be configured using block:

```ruby
MetaRequest.configure do |config|
  config.storage_pool_size = 30
end
```

List of available attributes and defaults can be found in [lib/meta_request/config.rb](lib/meta_request/config.rb).

## Docker

Apps running in Docker container will have filepaths of the container so links to editor would not work. To fix this, you need to propagate working directory through environment variable `SOURCE_PATH`. With docker-compose it can be done like this:

```yaml
services:
  app:
    environment:
      - SOURCE_PATH=$PWD
    # ...
```

## Development

Run all tests:

    docker-compose up

## Licence

Copyright (c) 2012 Dejan Simic

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
