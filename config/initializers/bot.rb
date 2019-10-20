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

module Facebook
  module Messenger
    module Incoming
      # The Message class represents an incoming Facebook Messenger message.
      class Message
        include Facebook::Messenger::Incoming::Common

        def app_id
          @messaging['message']['app_id']
        end
      end
    end
  end
end

class ExampleProvider < Facebook::Messenger::Configuration::Providers::Base
  def valid_verify_token?(_verify_token)
    ENV['fb_verify_token']
  end

  def app_secret_for(_page_id)
    ENV['fb_app_secret']
  end

  def access_token_for(page_id)
    FacebookPage.where(page_id: page_id).last.access_token
  end

  private

  def bot
    MyApp::Bot
  end
end

Facebook::Messenger.configure do |config|
  config.provider = ExampleProvider.new
end
