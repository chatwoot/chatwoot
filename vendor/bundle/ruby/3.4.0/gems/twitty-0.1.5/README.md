# Twitty

Ruby client for Twitter Business APIs

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'twitty'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install twitty

## Usage

Initialize twitty in your project in an intializer or as required  

```
$twitter = Twitty::Facade.new do |config|
 config.consumer_key = 'consumer key '
 config.consumer_secret = 'consumer secret'
 config.access_token = 'access token'
 config.access_token_secret = 'access token secret'
 config.base_url = 'https://api.twitter.com'
 config.environment = 'chatwootdev'
end
```

Use twitty to register your webhook on twitter as below

```
#fetch existing webhooks
$twitter.fetch_webhooks

#register a new webhook
$twitter.register_webhook(url: "https://xyc.com/webhooks/twitter")
```

You should handle the crc checks from twitter by processing the get requests to your webhooks url with a controller method similar to

```
 def twitter_crc
    render json: { response_token: "sha256=#{$twitter.generate_crc(params[:crc_token])}" }
 end
```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Adding new endpoints 

You can easily add new endpoints by adding a new hash with `url` and `required_params` in https://github.com/chatwoot/twitty/blob/master/lib/twitty/constants.rb

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chatwoot/twitty. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](https://www.chatwoot.com/docs/code-of-conduct) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Twitty project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://www.chatwoot.com/docs/code-of-conduct).
