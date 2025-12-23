# Net::HTTP

Net::HTTP provides a rich library which can be used to build HTTP
user-agents.  For more details about HTTP see
[RFC9110 HTTP Semantics](https://www.ietf.org/rfc/rfc9110.html) and
[RFC9112 HTTP/1.1](https://www.ietf.org/rfc/rfc9112.html).

Net::HTTP is designed to work closely with URI.  URI::HTTP#host,
URI::HTTP#port and URI::HTTP#request_uri are designed to work with
Net::HTTP.

If you are only performing a few GET requests you should try OpenURI.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'net-http'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install net-http

## Usage

All examples assume you have loaded Net::HTTP with:

```ruby
require 'net/http'
```

This will also require 'uri' so you don't need to require it separately.

The Net::HTTP methods in the following section do not persist
connections.  They are not recommended if you are performing many HTTP
requests.

### GET

```ruby
Net::HTTP.get('example.com', '/index.html') # => String
```

### GET by URI

```ruby
uri = URI('http://example.com/index.html?count=10')
Net::HTTP.get(uri) # => String
```

### GET with Dynamic Parameters

```ruby 
uri = URI('http://example.com/index.html')
params = { :limit => 10, :page => 3 }
uri.query = URI.encode_www_form(params)

res = Net::HTTP.get_response(uri)
puts res.body if res.is_a?(Net::HTTPSuccess)
```

### POST

```ruby
uri = URI('http://www.example.com/search.cgi')
res = Net::HTTP.post_form(uri, 'q' => 'ruby', 'max' => '50')
puts res.body
```

### POST with Multiple Values

```ruby
uri = URI('http://www.example.com/search.cgi')
res = Net::HTTP.post_form(uri, 'q' => ['ruby', 'perl'], 'max' => '50')
puts res.body
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/net-http.

