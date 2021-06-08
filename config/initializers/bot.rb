# Remember that Rails only eager loads everything in its production environment.
# In the development and test environments, it only requires files as you reference constants. 
# You'll need to explicitly load app/bot

unless Rails.env.production?
  bot_files = Dir[Rails.root.join('app', 'bot', '**', '*.rb')]
  bot_reloader = ActiveSupport::FileUpdateChecker.new(bot_files) do
    bot_files.each { |file| require_dependency file }
  end

  ActiveSupport::Reloader.to_prepare do
    bot_reloader.execute_if_updated
  end

  bot_files.each { |file| require_dependency file }
end

# ref: https://github.com/jgorset/facebook-messenger#make-a-configuration-provider
class ChatwootFbProvider < Facebook::Messenger::Configuration::Providers::Base
  def valid_verify_token?(_verify_token)
    ENV['FB_VERIFY_TOKEN']
  end

  def app_secret_for(_page_id)
    ENV['FB_APP_SECRET']
  end

  def access_token_for(page_id)
    Channel::FacebookPage.where(page_id: page_id).last.page_access_token
  end

  private

  def bot
    Chatwoot::Bot
  end
end

Facebook::Messenger.configure do |config|
  config.provider = ChatwootFbProvider.new
end
