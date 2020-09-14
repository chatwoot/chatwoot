require 'facebook/messenger'

class FacebookBot
  include Facebook::Messenger

  Bot.on :message do |message|
    Rails.logger.info "MESSAGE_RECIEVED #{message}"
    response = ::Integrations::Facebook::MessageParser.new(message)
    ::Integrations::Facebook::MessageCreator.new(response).perform
  end

  Bot.on :delivery do |delivery|
    # delivery.ids       # => 'mid.1457764197618:41d102a3e1ae206a38'
    # delivery.sender    # => { 'id' => '1008372609250235' }
    # delivery.recipient # => { 'id' => '2015573629214912' }
    # delivery.at        # => 2016-04-22 21:30:36 +0200
    # delivery.seq       # => 37
    updater = Integrations::Facebook::DeliveryStatus.new(delivery)
    updater.perform
    Rails.logger.info "Human was online at #{delivery.at}"
  end

  Bot.on :message_echo do |message|
    Rails.logger.info "MESSAGE_ECHO #{message}"
    response = ::Integrations::Facebook::MessageParser.new(message)
    ::Integrations::Facebook::MessageCreator.new(response).perform
  end
end
