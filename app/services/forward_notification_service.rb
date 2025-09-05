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
  rescue StandardError => e
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
      Rails.logger.warn "Not implemented notification channel: #{channel}"
    end
  end

  def send_whatsapp_notifications(target_chats)
    # Get the WhatsApp channel with provider "whapi"
    whatsapp_channel = @account.whatsapp_channels.find_by(provider: 'whapi')

    if whatsapp_channel.nil?
    default_api_key = ENV['DEFAULT_WHAPI_CHANNEL_TOKEN']
      if default_api_key.present?
        whatsapp_channel = create_whapi_channel(default_api_key)
      else
        Rails.logger.error "Account #{@account.id} with no whapi channel and no default whapi channel token defined"
      return
      end
    end

    # Validate that the channel has proper configuration
    unless whatsapp_channel&.provider_config&.dig('api_key').present?
      Rails.logger.warn "WhatsApp channel missing API key for account #{@account.id}"
      return
    end  

    target_chats.each do |chat_id|
      # Send to the WhatsApp channel
      send_via_whatsapp_channel(whatsapp_channel, chat_id, @message.content)
    end
  end

  def send_via_whatsapp_channel(whatsapp_channel, target_chat, notification_message)
    return if whatsapp_channel.nil? || target_chat.blank?

    # Create a proper message object for notification forwarding
    message_object = NotificationMessage.new(notification_message)

    # Create the WhapiService instance and send the message
    whapi_service = Whatsapp::Providers::WhapiService.new(whatsapp_channel: whatsapp_channel)
    whapi_service.send_message(target_chat, message_object)

  rescue StandardError => e
    Rails.logger.error "Failed to send WhatsApp notification to #{target_chat}: #{e.message}"
  end

  def create_whapi_channel(api_key)
    # Create a minimal channel object for notification forwarding
    NotificationChannel.new('whapi', api_key, @account)
  end

  # Simple wrapper class for notification forwarding
  class NotificationChannel
    attr_reader :provider, :provider_config, :account

    def initialize(provider, api_key, account)
      @provider = provider
      @provider_config = { 'api_key' => api_key }
      @account = account
    end

    def mark_message_templates_updated
      # No-op for notification forwarding
    end
  end

  # Message object for notification forwarding
  class NotificationMessage
    attr_reader :content, :content_type, :message_type, :private, :attachments, :content_attributes

    def initialize(content)
      @content = content
      @content_type = 'text'
      @message_type = 'outgoing'
      @private = false
      @attachments = []
      @content_attributes = {}
    end

    def outgoing_content
      content
    end
  end

  def find_notification_config
    store_id = @account.custom_attributes['store_id']
    return if store_id.blank?

    begin
      # Instantiate the configuration service
      config_service = AiBackendService::ConfigurationService.new

      # Use the configuration service to get notifications config
      notification_config = config_service.get_configuration(store_id, AiBackendService::ConfigurationService::CONFIGURATION_KEYS[:NOTIFICATIONS])

      return notification_config if notification_config.present?
    rescue StandardError => e
      Rails.logger.error "Error getting notification config: #{e.message}"
    end
  end
end