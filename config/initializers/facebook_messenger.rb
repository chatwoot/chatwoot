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

Rails.application.reloader.to_prepare do
  Facebook::Messenger.configure do |config|
    config.provider = ChatwootFbProvider.new
  end

  Facebook::Messenger::Bot.on :message do |message|
    Rails.logger.info "MESSAGE_RECIEVED #{message}"
    response = ::Integrations::Facebook::MessageParser.new(message)
    ::Integrations::Facebook::MessageCreator.new(response).perform
  end

  Facebook::Messenger::Bot.on :delivery do |delivery|
    # delivery.ids       # => 'mid.1457764197618:41d102a3e1ae206a38'
    # delivery.sender    # => { 'id' => '1008372609250235' }
    # delivery.recipient # => { 'id' => '2015573629214912' }
    # delivery.at        # => 2016-04-22 21:30:36 +0200
    # delivery.seq       # => 37
    updater = Integrations::Facebook::DeliveryStatus.new(delivery)
    updater.perform
    Rails.logger.info "Human was online at #{delivery.at}"
  end

  Facebook::Messenger::Bot.on :message_echo do |message|
    Rails.logger.info "MESSAGE_ECHO #{message}"
    response = ::Integrations::Facebook::MessageParser.new(message)
    ::Integrations::Facebook::MessageCreator.new(response).perform
  end
end
