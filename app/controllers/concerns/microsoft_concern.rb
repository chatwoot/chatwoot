module MicrosoftConcern
  extend ActiveSupport::Concern

  def microsoft_client
    ::OAuth2::Client.new(ENV.fetch('AZURE_APP_ID', nil), ENV.fetch('AZURE_APP_SECRET', nil),
                          {
                            site: 'https://login.microsoftonline.com',
                            authorize_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
                            token_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
                          })
  end

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
