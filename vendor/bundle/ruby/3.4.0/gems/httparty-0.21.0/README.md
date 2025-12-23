# httparty

[![CI](https://github.com/jnunemaker/httparty/actions/workflows/ci.yml/badge.svg)](https://github.com/jnunemaker/httparty/actions/workflows/ci.yml)

Makes http fun again!  Ain't no party like a httparty, because a httparty don't stop.

## Install

```
gem install httparty
```

## Requirements

* Ruby 2.3.0 or higher
* multi_xml
* You like to party!

## Examples

```ruby
# Use the class methods to get down to business quickly
response = HTTParty.get('http://api.stackexchange.com/2.2/questions?site=stackoverflow')

puts response.body, response.code, response.message, response.headers.inspect

# Or wrap things up in your own class
class StackExchange
  include HTTParty
  base_uri 'api.stackexchange.com'

  def initialize(service, page)
    @options = { query: { site: service, page: page } }
  end

  def questions
    self.class.get("/2.2/questions", @options)
  end

  def users
    self.class.get("/2.2/users", @options)
  end
end

stack_exchange = StackExchange.new("stackoverflow", 1)
puts stack_exchange.questions
puts stack_exchange.users
```

See the [examples directory](http://github.com/jnunemaker/httparty/tree/master/examples) for even more goodies.
## Command Line Interface

httparty also includes the executable `httparty` which can be
used to query web services and examine the resulting output. By default
it will output the response as a pretty-printed Ruby object (useful for
grokking the structure of output). This can also be overridden to output
formatted XML or JSON. Execute `httparty --help` for all the
options. Below is an example of how easy it is.

```
httparty "https://api.stackexchange.com/2.2/questions?site=stackoverflow"
```

## Help and Docs

* [Docs](https://github.com/jnunemaker/httparty/tree/master/docs)
* https://github.com/jnunemaker/httparty/discussions
* https://www.rubydoc.info/github/jnunemaker/httparty

## Contributing

* Fork the project.
* Run `bundle`
* Run `bundle exec rake`
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Run `bundle exec rake` (No, REALLY :))
* Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself in another branch so I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.
