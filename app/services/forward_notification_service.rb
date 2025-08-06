
# TODO: This is only functional right now with Whapi
class ForwardNotificationService
  # Don't include the class, we'll instantiate it
  
  def initialize(message)
    @message = message
    @conversation = message.conversation
    @account = @conversation.account
  end

  def send_notification
    # Find the notification channels and their target chats
    notification_channels = extract_notification_channels
    return if notification_channels.empty?

    notification_channels.each do |channel_config|
      send_to_channel(channel_config)
    end
  rescue => e
    Rails.logger.error "Error in ForwardNotificationService.send_notification: #{e.message}"
  end

  private

  def extract_notification_channels
    notification_config = find_notification_config
    return [] unless notification_config&.dig('channels')

    channels = []
    notification_config['channels'].each do |channel_data|
      channel = channel_data['channel']
      target_chats = channel_data['target_chats'] || []
      
      channels << {
        channel: channel,
        target_chats: target_chats
      }
    end
    
    channels
  end

  def send_to_channel(channel_config)
    channel = channel_config[:channel]
    target_chats = channel_config[:target_chats]
    
    case channel
    when 'whatsapp'
      send_whatsapp_notifications(target_chats)
    else
      Rails.logger.warn "Unknown notification channel: #{channel}"
    end
  end

  def send_whatsapp_notifications(target_chats)
    # Get the WhatsApp channel with provider "whapi"
    whatsapp_channel = @account.whatsapp_channels.find_by(provider: 'whapi')

    if whatsapp_channel.nil?
      Rails.logger.warn "No WhatsApp channels with provider 'whapi' found for account #{@account.id}"
      return
    end

    target_chats.each do |chat_id|
      # Send to the WhatsApp channel
      send_via_whatsapp_channel(whatsapp_channel, chat_id, @message.content)
    end
  end

  def send_via_whatsapp_channel(whatsapp_channel, target_chat, notification_message)
    begin
      # Create a message object that the WhatsApp channel can send
      message_object = OpenStruct.new(
        content: notification_message,
        content_type: 'text',
        message_type: 'outgoing',
        private: false,
        attachments: [],
        content_attributes: {}
      )
      
      # Add the outgoing_content method
      def message_object.outgoing_content
        content
      end
      
      # Send the message using the WhatsApp channel
      message_id = whatsapp_channel.send_message(target_chat, message_object)
      
      Rails.logger.info "WhatsApp notification sent successfully to #{target_chat}. Message ID: #{message_id}"
      
    rescue => e
      Rails.logger.error "Failed to send WhatsApp notification to #{target_chat}: #{e.message}"
    end
  end

  def find_notification_config
    store_id = @account.custom_attributes['store_id']
    return unless store_id.present?
    
    begin
      # Instantiate the configuration service
      config_service = ChatscommerceService::ConfigurationService.new
      
      # Use the configuration service to get notifications config
      notification_config = config_service.get_configuration(store_id, ChatscommerceService::ConfigurationService::CONFIGURATION_KEYS[:NOTIFICATIONS])
      
      return notification_config if notification_config.present?
    rescue => e
      Rails.logger.error "Error getting notification config: #{e.message}"
    end
  end
  
end