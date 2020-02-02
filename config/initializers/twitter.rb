$twitter = Twitty::Facade.new do |config|
  config.consumer_key = ENV.fetch('TWITTER_CONSUMER_KEY', nil)
  config.consumer_secret = ENV.fetch('TWITTER_CONSUMER_SECRET', nil)
  config.access_token = ENV.fetch('TWITTER_ACCESS_TOKEN', nil)
  config.access_token_secret = ENV.fetch('TWITTER_ACCESS_TOKEN_SECRET', nil)
  config.base_url = 'https://api.twitter.com'
  config.environment = 'chatwootstaging'
end
