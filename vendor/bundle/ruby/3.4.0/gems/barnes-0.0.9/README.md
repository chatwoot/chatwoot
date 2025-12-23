## Barnes - GC Statsd Reporter

A fork of [trashed](https://github.com/basecamp/trashed) focused on Ruby metrics for Heroku.

## Setup

### Rails 3, 4, 5, and 6

On Rails 6 (and Rails 3 and 4 and 5), add this to your Gemfile:

```
gem "barnes"
```

Then run:

```
$ bundle install
```

### Non-Rails

Add the gem to the Gemfile

```
gem "barnes"
```

Then run:

```
$ bundle install
```

In your puma.rb file:


```ruby
require 'barnes'
```

Then you'll need to start the client with default values:

```ruby
before_fork do
  # worker configuration
  Barnes.start
end
```

