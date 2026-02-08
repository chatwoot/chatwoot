module TwitterConcern
  extend ActiveSupport::Concern

  private

  def parsed_body
    @parsed_body ||= Rack::Utils.parse_nested_query(@response.raw_response.body)
  end

  def host
    ENV.fetch('FRONTEND_URL', '')
  end

  def twitter_client
    Twitty::Facade.new do |config|
      config.consumer_key = ENV.fetch('TWITTER_CONSUMER_KEY', nil)
      config.consumer_secret = ENV.fetch('TWITTER_CONSUMER_SECRET', nil)
      config.base_url = twitter_api_base_url
      config.environment = ENV.fetch('TWITTER_ENVIRONMENT', '')
    end
  end

  def twitter_api_base_url
    'https://api.twitter.com'
  end
end
