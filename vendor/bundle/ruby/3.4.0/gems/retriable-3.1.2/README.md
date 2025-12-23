# Retriable

[![Build Status](https://secure.travis-ci.org/kamui/retriable.svg)](http://travis-ci.org/kamui/retriable)
[![Code Climate](https://codeclimate.com/github/kamui/retriable/badges/gpa.svg)](https://codeclimate.com/github/kamui/retriable)
[![Test Coverage](https://codeclimate.com/github/kamui/retriable/badges/coverage.svg)](https://codeclimate.com/github/kamui/retriable)

Retriable is a simple DSL to retry failed code blocks with randomized [exponential backoff](http://en.wikipedia.org/wiki/Exponential_backoff) time intervals. This is especially useful when interacting external APIs, remote services, or file system calls.

## Requirements

Ruby 2.0.0+

If you need ruby 1.9.3 support, use the [2.x branch](https://github.com/kamui/retriable/tree/2.x) by specifying `~2.1` in your Gemfile.

If you need ruby 1.8.x to 1.9.2 support, use the [1.x branch](https://github.com/kamui/retriable/tree/1.x) by specifying `~1.4` in your Gemfile.

## Installation

Via command line:

```ruby
gem install retriable
```

In your ruby script:

```ruby
require 'retriable'
```

In your Gemfile:

```ruby
gem 'retriable', '~> 3.1'
```

## Usage
Code in a `Retriable.retriable` block will be retried if an exception is raised.

```ruby
require 'retriable'

class Api
  # Use it in methods that interact with unreliable services
  def get
    Retriable.retriable do
      # code here...
    end
  end
end
```

### Defaults
By default, `Retriable` will:
* rescue any exception inherited from `StandardError`
* make 3 tries (including the initial attempt) before raising the last exception
* use randomized exponential backoff to calculate each succeeding try interval.

The default interval table with 10 tries looks like this (in seconds, rounded to the nearest millisecond):

| Retry #  | Min      | Average  | Max      |
| -------- | -------- | -------- | -------- |
| 1        | `0.25`   | `0.5`    | `0.75`   |
| 2        | `0.375`  | `0.75`   | `1.125`  |
| 3        | `0.563`  | `1.125`  | `1.688`  |
| 4        | `0.844`  | `1.688`  | `2.531`  |
| 5        | `1.266`  | `2.531`  | `3.797`  |
| 6        | `1.898`  | `3.797`  | `5.695`  |
| 7        | `2.848`  | `5.695`  | `8.543`  |
| 8        | `4.271`  | `8.543`  | `12.814` |
| 9        | `6.407`  | `12.814` | `19.222` |
| 10       | **stop** | **stop** | **stop** |


### Options

Here are the available options, in some vague order of relevance to most common use patterns:

| Option | Default | Definition |
| ------ | ------- | ---------- |
| **`tries`** | `3` | Number of attempts to make at running your code block (includes initial attempt). |
| **`on`** | `[StandardError]` | Type of exceptions to retry. [Read more](#configuring-which-options-to-retry-with-on). |
| **`on_retry`** | `nil` | `Proc` to call after each try is rescued. [Read more](#callbacks). |
| **`base_interval`** | `0.5` | The initial interval in seconds between tries. |
| **`max_elapsed_time`** | `900` (15 min) | The maximum amount of total time in seconds that code is allowed to keep being retried. |
| **`max_interval`** | `60` | The maximum interval in seconds that any individual retry can reach. |
| **`multiplier`** | `1.5` | Each successive interval grows by this factor. A multipler of 1.5 means the next interval will be 1.5x the current interval. |
| **`timeout`** | `nil` | Number of seconds to allow the code block to run before raising a `Timeout::Error` inside each try. `nil` means the code block can run forever without raising error. (You may want to read up on [the dangers of using Ruby `Timeout`](https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/) before using this feature.) |
| **`rand_factor`** | `0.25` | The percentage to randomize the next retry interval time. The next interval calculation is `randomized_interval = retry_interval * (random value in range [1 - randomization_factor, 1 + randomization_factor])` |
| **`intervals`** | `nil` | Skip generated intervals and provide your own array of intervals in seconds. [Read more](#custom-interval-array). |

#### Configuring Which Options to Retry With :on
**`:on`** Can take the form:

- An `Exception` class (retry every exception of this type, including subclasses)
- An `Array` of `Exception` classes (retry any exception of one of these types, including subclasses)
- A `Hash` where the keys are `Exception` classes and the values are one of:
  - `nil` (retry every exception of the key's type, including subclasses)
  - A single `Regexp` pattern (retries exceptions ONLY if their `message` matches the pattern)
  - An array of patterns (retries exceptions ONLY if their `message` matches at least one of the patterns)


### Configuration

You can change the global defaults with a `#configure` block:

```ruby
Retriable.configure do |c|
  c.tries = 5
  c.max_elapsed_time = 3600 # 1 hour
end
```

### Example Usage

This example will only retry on a `Timeout::Error`, retry 3 times and sleep for a full second before each try.

```ruby
Retriable.retriable(on: Timeout::Error, tries: 3, base_interval: 1) do
  # code here...
end
```

You can also specify multiple errors to retry on by passing an array of exceptions.

```ruby
Retriable.retriable(on: [Timeout::Error, Errno::ECONNRESET]) do
  # code here...
end
```

You can also use a hash to specify that you only want to retry exceptions with certain messages (see [the documentation above](#configuring-which-options-to-retry-with-on)).  This example will retry all `ActiveRecord::RecordNotUnique` exceptions, `ActiveRecord::RecordInvalid` exceptions where the message matches either `/Parent must exist/` or `/Username has already been taken/`, or `Mysql2::Error` exceptions where the message matches `/Duplicate entry/`.

```ruby
Retriable.retriable(on: {
  ActiveRecord::RecordNotUnique => nil,
  ActiveRecord::RecordInvalid => [/Parent must exist/, /Username has already been taken/],
  Mysql2::Error => /Duplicate entry/
}) do
  # code here...
end
```

You can also specify a timeout if you want the code block to only try for X amount of seconds. This timeout is per try. (You may want to read up on [the dangers of using Ruby `Timeout`](https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/) before using this feature.)

```ruby
Retriable.retriable(timeout: 60) do
  # code here...
end
```

If you need millisecond units of time for the sleep or the timeout:

```ruby
Retriable.retriable(base_interval: (200 / 1000.0), timeout: (500 / 1000.0)) do
  # code here...
end
```

### Custom Interval Array

You can also bypass the built-in interval generation and provide your own array of intervals. Supplying your own intervals overrides the `tries`, `base_interval`, `max_interval`, `rand_factor`, and `multiplier` parameters.

```ruby
Retriable.retriable(intervals: [0.5, 1.0, 2.0, 2.5]) do
  # code here...
end
```

This example makes 5 total attempts. If the first attempt fails, the 2nd attempt occurs 0.5 seconds later.

### Turn off Exponential Backoff

Exponential backoff is enabled by default.  If you want to simply retry code every second, 5 times maximum, you can do this:

```ruby
Retriable.retriable(tries: 5, base_interval: 1.0, multiplier: 1.0, rand_factor: 0.0) do
  # code here...
end
```

This works by starting at a 1 second `base_interval`.  Setting the `multipler` to 1.0 means each subsequent try will increase 1x, which is still `1.0` seconds, and then a `rand_factor` of 0.0 means that there's no randomization of that interval. (By default, it would randomize 0.25 seconds, which would mean normally the intervals would randomize between 0.75 and 1.25 seconds, but in this case `rand_factor` is basically being disabled.)

Another way to accomplish this would be to create an array with a fixed interval. In this example, `Array.new(5, 1)` creates an array with 5 elements, all with the value 1. The code block will retry up to 5 times, and wait 1 second between each attempt.

```ruby
# Array.new(5, 1) # => [1, 1, 1, 1, 1]

Retriable.retriable(intervals: Array.new(5, 1)) do
  # code here...
end
```

If you don't want exponential backoff but you still want some randomization between intervals, this code will run every 1 seconds with a randomization factor of 0.2, which means each interval will be a random value between 0.8 and 1.2 (1 second +/- 0.2):

```ruby
Retriable.retriable(base_interval: 1.0, multiplier: 1.0, rand_factor: 0.2) do
  # code here...
end
```

### Callbacks

`#retriable` also provides a callback called `:on_retry` that will run after an exception is rescued. This callback provides the `exception` that was raised in the current try, the `try_number`, the `elapsed_time` for all tries so far, and the time in seconds of the `next_interval`. As these are specified in a `Proc`, unnecessary variables can be left out of the parameter list.

```ruby
do_this_on_each_retry = Proc.new do |exception, try, elapsed_time, next_interval|
  log "#{exception.class}: '#{exception.message}' - #{try} tries in #{elapsed_time} seconds and #{next_interval} seconds until the next try."
end

Retriable.retriable(on_retry: do_this_on_each_retry) do
  # code here...
end
```

### Ensure/Else

What if I want to execute a code block at the end, whether or not an exception was rescued ([ensure](http://ruby-doc.org/docs/keywords/1.9/Object.html#method-i-ensure))? Or what if I want to execute a code block if no exception is raised ([else](http://ruby-doc.org/docs/keywords/1.9/Object.html#method-i-else))? Instead of providing more callbacks, I recommend you just wrap retriable in a begin/retry/else/ensure block:

```ruby
begin
  Retriable.retriable do
    # some code
  end
rescue => e
  # run this if retriable ends up re-rasing the exception
else
  # run this if retriable doesn't raise any exceptions
ensure
  # run this no matter what, exception or no exception
end
```

## Contexts

Contexts allow you to coordinate sets of Retriable options across an application.  Each context is basically an argument hash for `Retriable.retriable` that is stored in the `Retriable.config` as a simple `Hash` and is accessible by name. For example:

```ruby
Retriable.configure do |c|
  c.contexts[:aws] = {
    tries: 3,
    base_interval: 5,
    on_retry: Proc.new { puts 'Curse you, AWS!' }
  }
  c.contexts[:mysql] = {
    tries: 10,
    multiplier: 2.5,
    on: Mysql::DeadlockException
  }
end
```

This will create two contexts, `aws` and `mysql`, which allow you to reuse different backoff strategies across your application without continually passing those strategy options to the `retriable` method.

These are used simply by calling `Retriable.with_context`:

```ruby
# Will retry all exceptions
Retriable.with_context(:aws) do
  # aws_call
end

# Will retry Mysql::DeadlockException
Retriable.with_context(:mysql) do
  # write_to_table
end
```

You can even temporarily override individual options for a configured context:

```ruby
Retriable.with_context(:mysql, tries: 30) do
  # write_to_table with :mysql context, except with 30 tries instead of 10
end
```

## Kernel Extension

If you want to call `Retriable.retriable` without the `Retriable` module prefix and you don't mind extending `Kernel`,
there is a kernel extension available for this.

In your ruby script:

```ruby
require 'retriable/core_ext/kernel'
```

or in your Gemfile:

```ruby
gem 'retriable', require: 'retriable/core_ext/kernel'
```

and then you can call `#retriable` in any context like this:

```ruby
retriable do
  # code here...
end

retriable_with_context(:api) do
  # code here...
end
```

## Short Circuiting Retriable While Testing Your App

When you are running tests for your app it often takes a long time to retry blocks that fail. This is because Retriable will default to 3 tries with exponential backoff. Ideally your tests will run as quickly as possible.

You can disable retrying by setting `tries` to 1 in the test environment. If you want to test that the code is retrying an error, you want to [turn off exponential backoff](#turn-off-exponential-backoff).

Under Rails, you could change your initializer to have different options in test, as follows:

```ruby
# config/initializers/retriable.rb
Retriable.configure do |c|
  # ... default configuration

  if Rails.env.test?
    c.tries = 1
  end
end
```

Alternately, if you are using RSpec, you could override the Retriable confguration in your `spec_helper`.

```ruby
# spec/spec_helper.rb
Retriable.configure do |c|
  c.tries = 1
end
```

If you have defined contexts for your configuration, you'll need to change values for each context, because those values take precedence over the default configured value.

For example assuming you have configured a `google_api` context:
```ruby
# config/initializers/retriable.rb
Retriable.configure do |c|
  c.contexts[:google_api] = {
      tries:         5,
      base_interval: 3,
      on:            [
          Net::ReadTimeout,
          Signet::AuthorizationError,
          Errno::ECONNRESET,
          OpenSSL::SSL::SSLError
      ]
  }
end
```

Then in your test environment, you would need to set each context and the default value:

```ruby
# spec/spec_helper.rb
Retriable.configure do |c|
  c.multiplier    = 1.0
  c.rand_factor   = 0.0
  c.base_interval = 0

  c.contexts.keys.each do |context|
    c.contexts[context][:tries]         = 1
    c.contexts[context][:base_interval] = 0
  end
end
```

## Proxy Wrapper Object

[@julik](https://github.com/julik) has created a gem called [retriable_proxy](https://github.com/julik/retriable_proxy) that extends `retriable` with the ability to wrap objects and specify which methods you want to be retriable, like so:

```ruby
# api_endpoint is an instance of some kind of class that connects to an API
RetriableProxy.for_object(api_endpoint, on: Net::TimeoutError)
```

## Credits

The randomized exponential backoff implementation was inspired by the one used in Google's [google-http-java-client](https://code.google.com/p/google-http-java-client/wiki/ExponentialBackoff) project.

## Development
### Running Specs
```bash
bundle exec rspec
```
