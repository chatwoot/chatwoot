class Whatsapp::IncomingMessageBaileysService < Whatsapp::IncomingMessageBaseService
  class InvalidWebhookVerifyToken < StandardError; end

  def perform
    raise InvalidWebhookVerifyToken if processed_params[:webhookVerifyToken] != inbox.channel.provider_config['webhook_verify_token']
    return if processed_params[:event].blank? || processed_params[:data].blank?

    event_prefix = processed_params[:event].gsub(/[\.-]/, '_')
    method_name = "process_#{event_prefix}"
    if respond_to?(method_name, true)
      # TODO: Implement the methods for all expected events
      send(method_name)
    else
      Rails.logger.warn "Baileys unsupported event: #{processed_params[:event]}"
    end
  end

  private

  def process_connection_update
    data = processed_params[:data]

    # NOTE: `connection` values
    #   - `close`: Never opened, or closed and no longer able to send/receive messages
    #   - `connecting`: In the process of connecting, expecting QR code to be read
    #   - `reconnecting`: Connection has been established, but not open (i.e. device is being linked for the first time, or Baileys server restart)
    #   - `open`: Open and ready to send/receive messages
    inbox.channel.update_provider_connection!({
      connection: data[:connection] || inbox.channel.provider_connection['connection'],
      qr_data_url: data[:qrDataUrl] || nil,
      error: data[:error] ? I18n.t("errors.inboxes.channel.provider_connection.#{data[:error]}") : nil
    }.compact)

    Rails.logger.error "Baileys connection error: #{data[:error]}" if data[:error].present?
  end

  def process_messages_upsert
    messages = processed_params[:data][:messages]
    messages.each do |message|
      @message = nil
      @contact_inbox = nil
      @contact = nil
      @raw_message = message
      handle_message
    end
  end

  def handle_message
    return if jid_type != 'user'
    return if find_message_by_source_id(message_id) || message_under_process?

    cache_message_source_id_in_redis
    set_contact

    unless @contact
      Rails.logger.warn "Contact not found for message: #{message_id}"
      return
    end

    set_conversation
    handle_create_message
    clear_message_source_id_from_redis
  end

  def set_contact
    # NOTE: jid shape is `<user>_<agent>:<device>@<server>`
    # https://github.com/WhiskeySockets/Baileys/blob/v6.7.16/src/WABinary/jid-utils.ts#L19
    phone_number_from_jid = @raw_message[:key][:remoteJid].split('@').first.split(':').first.split('_').first
    phone_number_formatted = "+#{phone_number_from_jid}"
    # NOTE: We're assuming `pushName` will always be present when `fromMe: false`.
    # This assumption might be incorrect, so let's keep an eye out for contacts being created with empty name.
    push_name = @raw_message[:key][:fromMe] ? phone_number_formatted : @raw_message[:pushName].to_s
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: phone_number_from_jid,
      inbox: inbox,
      contact_attributes: { name: push_name, phone_number: phone_number_formatted }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    @contact.update!(name: push_name) if @contact.name == phone_number_formatted && !@raw_message[:key][:fromMe]
  end

  def handle_create_message
    case message_type
    when 'text'
      create_text_message
    else
      Rails.logger.warn "Baileys unsupported message type: #{message_type}"
    end
  end

  def jid_type # rubocop:disable Metrics/CyclomaticComplexity
    jid = @raw_message[:key][:remoteJid]
    server = jid.split('@').last

    # NOTE: Based on Baileys internal functions
    # https://github.com/WhiskeySockets/Baileys/blob/v6.7.16/src/WABinary/jid-utils.ts#L48-L58
    case server
    when 's.whatsapp.net', 'c.us'
      'user'
    when 'g.us'
      'group'
    when 'lid'
      'lid'
    when 'broadcast'
      jid.start_with?('status@') ? 'status' : 'broadcast'
    when 'newsletter'
      'newsletter'
    when 'call'
      'call'
    else
      'unknown'
    end
  end

  def message_type # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    msg = @raw_message[:message]

    return 'text' if msg.key?(:conversation) || msg.dig(:extendedTextMessage, :text).present?
    return 'contacts' if msg.key?(:contactMessage)
    return 'image' if msg.key?(:imageMessage)
    return 'audio' if msg.key?(:audioMessage)
    return 'video' if msg.key?(:videoMessage)
    return 'video_note' if msg.key?(:ptvMessage)
    return 'location' if msg.key?(:locationMessage)
    return 'live_location' if msg.key?(:liveLocationMessage)
    return 'document' if msg.key?(:documentMessage)
    return 'poll' if msg.key?(:pollCreationMessageV3)
    return 'event' if msg.key?(:eventMessage)
    return 'sticker' if msg.key?(:stickerMessage)

    'unsupported'
  end

  def create_text_message
    is_outgoing = @raw_message[:key][:fromMe]
    sender = is_outgoing ? @inbox.account.account_users.first.user : @contact
    sender_type = is_outgoing ? 'User' : 'Contact'
    message_type = is_outgoing ? :outgoing : :incoming
    content = @raw_message.dig(:message, :conversation) || @raw_message.dig(:message, :extendedTextMessage, :text)

    @message = @conversation.messages.create!(
      content: content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      source_id: message_id,
      sender: sender,
      sender_type: sender_type,
      message_type: message_type,
      in_reply_to_external_id: nil
    )
  end

  def message_id
    @raw_message[:key][:id]
  end

  def message_under_process?
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: message_id)
    Redis::Alfred.get(key)
  end

  def cache_message_source_id_in_redis
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: message_id)
    ::Redis::Alfred.setex(key, true)
  end

  def clear_message_source_id_from_redis
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: message_id)
    ::Redis::Alfred.delete(key)
  end
end
