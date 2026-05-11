# ref: https://github.com/jgorset/facebook-messenger#make-a-configuration-provider
class ChatwootFbProvider < Facebook::Messenger::Configuration::Providers::Base
  def valid_verify_token?(_verify_token)
    GlobalConfigService.load('FB_VERIFY_TOKEN', '')
  end

  def app_secret_for(_page_id)
    GlobalConfigService.load('FB_APP_SECRET', '')
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
    Webhooks::FacebookEventsJob.perform_later(message.to_json)
  end

  Facebook::Messenger::Bot.on :delivery do |delivery|
    Rails.logger.info "Recieved delivery status #{delivery.to_json}"
    Webhooks::FacebookDeliveryJob.perform_later(delivery.to_json)
  end

  Facebook::Messenger::Bot.on :read do |read|
    Rails.logger.info "Recieved read status  #{read.to_json}"
    Webhooks::FacebookDeliveryJob.perform_later(read.to_json)
  end

  Facebook::Messenger::Bot.on :message_echo do |message|
    # Add delay to prevent race condition where echo arrives before send message API completes
    # This avoids duplicate messages when echo comes early during API processing
    Webhooks::FacebookEventsJob.set(wait: 2.seconds).perform_later(message.to_json)
  end

  # Extend Bot::EVENTS to support reaction events (the gem parses them but doesn't whitelist them)
  Facebook::Messenger::Bot::EVENTS.push(:reaction) unless Facebook::Messenger::Bot::EVENTS.include?(:reaction)

  Facebook::Messenger::Bot.on :reaction do |reaction|
    reaction_json = JSON.parse(reaction.to_json)
    messaging = reaction_json['messaging'] || reaction_json
    reaction_data = messaging['reaction'] || reaction_json['reaction']
    next unless reaction_data

    mid = reaction_data['mid']
    action = reaction_data['action']
    emoji = reaction_data['emoji']
    sender_id = (messaging.dig('sender', 'id') || reaction_json.dig('sender', 'id')).to_s

    target_message = Message.find_by(source_id: mid)
    next unless target_message

    reactions = target_message.content_attributes['reactions'] || []
    reactions.reject! { |r| r['sender_source_id'] == sender_id }

    if action == 'react' && emoji.present?
      reactions << {
        'emoji' => emoji,
        'sender_source_id' => sender_id,
        'timestamp' => Time.current.to_i
      }
    end

    target_message.content_attributes['reactions'] = reactions
    target_message.save!
    target_message.send_update_event
  end
end
