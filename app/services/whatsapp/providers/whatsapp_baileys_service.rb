class Whatsapp::Providers::WhatsappBaileysService < Whatsapp::Providers::BaseService # rubocop:disable Metrics/ClassLength
  include BaileysHelper

  class MessageContentTypeNotSupported < StandardError; end
  class MessageNotSentError < StandardError; end

  DEFAULT_CLIENT_NAME = ENV.fetch('BAILEYS_PROVIDER_DEFAULT_CLIENT_NAME', nil)
  DEFAULT_URL = ENV.fetch('BAILEYS_PROVIDER_DEFAULT_URL', nil)
  DEFAULT_API_KEY = ENV.fetch('BAILEYS_PROVIDER_DEFAULT_API_KEY', nil)

  def setup_channel_provider
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}",
      headers: api_headers,
      body: {
        clientName: DEFAULT_CLIENT_NAME,
        webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
        webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
        # TODO: Remove on Baileys v2, default will be false
        includeMedia: false
      }.to_json
    )

    process_response(response)
  end

  def disconnect_channel_provider
    response = HTTParty.delete(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}",
      headers: api_headers
    )

    process_response(response)
  end

  def send_message(phone_number, message)
    @message = message
    @phone_number = phone_number

    if message.content_attributes[:is_reaction]
      @message_content = reaction_message_content
    elsif message.attachments.present?
      @message_content = attachment_message_content
    elsif message.content.present?
      @message_content = { text: @message.content }
    else
      @message.update!(is_unsupported: true)
      return
    end

    send_message_request
  end

  def send_template(phone_number, template_info); end

  def sync_templates; end

  def media_url(media_id)
    "#{provider_url}/media/#{media_id}"
  end

  def api_headers
    { 'x-api-key' => api_key, 'Content-Type' => 'application/json' }
  end

  def validate_provider_config?
    response = HTTParty.get(
      "#{provider_url}/status/auth",
      headers: api_headers
    )

    process_response(response)
  end

  def toggle_typing_status(phone_number, typing_status)
    @phone_number = phone_number
    status_map = {
      Events::Types::CONVERSATION_TYPING_ON => 'composing',
      Events::Types::CONVERSATION_RECORDING => 'recording',
      Events::Types::CONVERSATION_TYPING_OFF => 'paused'
    }

    response = HTTParty.patch(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/presence",
      headers: api_headers,
      body: {
        toJid: remote_jid,
        type: status_map[typing_status]
      }.to_json
    )

    process_response(response)
  end

  def update_presence(status)
    status_map = {
      'online' => 'available',
      'offline' => 'unavailable',
      'busy' => 'unavailable'
    }

    response = HTTParty.patch(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/presence",
      headers: api_headers,
      body: {
        type: status_map[status]
      }.to_json
    )

    process_response(response)
  end

  def read_messages(phone_number, messages)
    @phone_number = phone_number

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/read-messages",
      headers: api_headers,
      body: {
        keys: messages.map do |message|
          {
            id: message.source_id,
            remoteJid: remote_jid,
            # NOTE: It only makes sense to mark received messages as read
            fromMe: false
          }
        end
      }.to_json
    )

    process_response(response)
  end

  def unread_message(phone_number, message) # rubocop:disable Metrics/MethodLength
    @phone_number = phone_number

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/chat-modify",
      headers: api_headers,
      body: {
        jid: remote_jid,
        mod: {
          markRead: false,
          lastMessages: [{
            key: {
              id: message.source_id,
              remoteJid: remote_jid,
              fromMe: message.message_type == 'outgoing'
            },
            messageTimestamp: message.content_attributes[:external_created_at]
          }]
        }
      }.to_json
    )

    process_response(response)
  end

  private

  def provider_url
    whatsapp_channel.provider_config['provider_url'].presence || DEFAULT_URL
  end

  def api_key
    whatsapp_channel.provider_config['api_key'].presence || DEFAULT_API_KEY
  end

  def reaction_message_content
    reply_to = Message.find(@message.in_reply_to)
    {
      react: { key: { id: reply_to.source_id,
                      remoteJid: remote_jid,
                      fromMe: reply_to.message_type == 'outgoing' },
               text: @message.content }
    }
  end

  def attachment_message_content # rubocop:disable Metrics/MethodLength
    attachment = @message.attachments.first
    buffer = Base64.strict_encode64(attachment.file.download)

    content = {
      fileName: attachment.file.filename,
      caption: @message.content
    }
    case attachment.file_type
    when 'image'
      content[:image] = buffer
    when 'audio'
      content[:audio] = buffer
      content[:ptt] = attachment.meta&.dig('is_recorded_audio')
    when 'file'
      content[:document] = buffer
    when 'sticker'
      content[:sticker] = buffer
    when 'video'
      content[:video] = buffer
    end

    content.compact
  end

  def send_message_request
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/send-message",
      headers: api_headers,
      body: {
        jid: remote_jid,
        messageContent: @message_content
      }.to_json
    )

    raise MessageNotSentError unless process_response(response)

    update_external_created_at(response)
    response.parsed_response.dig('data', 'key', 'id')
  end

  def process_response(response)
    Rails.logger.error response.body unless response.success?
    response.success?
  end

  def remote_jid
    "#{@phone_number.delete('+')}@s.whatsapp.net"
  end

  def update_external_created_at(response)
    timestamp = response.parsed_response.dig('data', 'messageTimestamp')
    return unless timestamp

    external_created_at = baileys_extract_message_timestamp(timestamp)
    @message.update!(external_created_at: external_created_at)
  end

  private_class_method def self.with_error_handling(*method_names)
    method_names.each do |method_name|
      original_method = instance_method(method_name)

      define_method(method_name) do |*args, &block|
        original_method.bind_call(self, *args, &block)
      rescue StandardError => e
        handle_channel_error
        raise e
      end
    end
  end

  def handle_channel_error
    whatsapp_channel.update_provider_connection!(connection: 'close')
  end

  with_error_handling :setup_channel_provider,
                      :disconnect_channel_provider,
                      :send_message,
                      :toggle_typing_status,
                      :update_presence,
                      :read_messages,
                      :unread_message
end
