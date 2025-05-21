class Whatsapp::IncomingMessageBaileysService < Whatsapp::IncomingMessageBaseService # rubocop:disable Metrics/ClassLength
  class InvalidWebhookVerifyToken < StandardError; end
  class MessageNotFoundError < StandardError; end
  class AttachmentNotFoundError < StandardError; end

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
    return if message_type == 'protocol'

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
    push_name = contact_name
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      # FIXME: update the source_id to complete jid in future
      source_id: phone_number_from_jid,
      inbox: inbox,
      contact_attributes: { name: push_name, phone_number: "+#{phone_number_from_jid}" }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    @contact.update!(name: push_name) if @contact.name == phone_number_from_jid
  end

  def phone_number_from_jid
    # NOTE: jid shape is `<user>_<agent>:<device>@<server>`
    # https://github.com/WhiskeySockets/Baileys/blob/v6.7.16/src/WABinary/jid-utils.ts#L19
    @phone_number_from_jid ||= @raw_message[:key][:remoteJid].split('@').first.split(':').first.split('_').first
  end

  def contact_name
    # NOTE: `verifiedBizName` is only available for business accounts and has a higher priority than `pushName`.
    name = @raw_message[:verifiedBizName].presence || @raw_message[:pushName]
    return name if self_message? || incoming?

    phone_number_from_jid
  end

  def self_message?
    # TODO: Handle denormalized Brazilian phone numbers
    phone_number_from_jid == inbox.channel.phone_number.delete('+')
  end

  def handle_create_message
    return if message_type == 'protocol' ||
              (message_type == 'reaction' && message_content.blank?)

    create_message(attach_media: %w[image file video audio sticker].include?(message_type))
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

  def message_type # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
    msg = @raw_message[:message]
    @message_type ||= if msg.key?(:conversation) || msg.dig(:extendedTextMessage, :text).present?
                        'text'
                      elsif msg.key?(:imageMessage)
                        'image'
                      elsif msg.key?(:audioMessage)
                        'audio'
                      elsif msg.key?(:videoMessage)
                        'video'
                      elsif msg.key?(:documentMessage)
                        'file'
                      elsif msg.key?(:stickerMessage)
                        'sticker'
                      elsif msg.key?(:reactionMessage)
                        'reaction'
                      elsif msg.key?(:protocolMessage)
                        'protocol'
                      else
                        'unsupported'
                      end
  end

  def create_message(attach_media: false)
    @message = @conversation.messages.build(
      content: message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      source_id: message_id,
      sender: incoming? ? @contact : @inbox.account.account_users.first.user,
      sender_type: incoming? ? 'Contact' : 'User',
      message_type: incoming? ? :incoming : :outgoing,
      content_attributes: message_content_attributes
    )

    handle_attach_media if attach_media

    @message.save!
  end

  def message_content_attributes
    content_attributes = {
      external_created_at: @raw_message[:messageTimestamp]
    }
    if message_type == 'reaction'
      content_attributes[:in_reply_to_external_id] = @raw_message.dig(:message, :reactionMessage, :key, :id)
      content_attributes[:is_reaction] = true
    elsif message_type == 'unsupported'
      content_attributes[:is_unsupported] = true
    end

    content_attributes
  end

  def incoming?
    !@raw_message[:key][:fromMe]
  end

  def handle_attach_media
    attachment_file = download_attachment_file
    return unless attachment_file

    attachment = @message.attachments.build(
      account_id: @message.account_id,
      file_type: file_content_type.to_s,
      file: { io: attachment_file, filename: filename, content_type: message_mimetype }
    )
    attachment.meta = { is_recorded_audio: true } if @raw_message.dig(:message, :audioMessage, :ptt)
  end

  def download_attachment_file
    Down.download(@conversation.inbox.channel.media_url(@raw_message.dig(:key, :id)), headers: @conversation.inbox.channel.api_headers)
  end

  def file_content_type
    return :image if message_type.in?(%w[image sticker])
    return :video if message_type.in?(%w[video video_note])
    return :audio if message_type == 'audio'

    :file
  end

  def filename
    filename = @raw_message.dig(:message, :documentMessage, :fileName)
    return filename if filename.present?

    ext = ".#{message_mimetype.split(';').first.split('/').last}" if message_mimetype.present?
    "#{file_content_type}_#{message_id}_#{Time.current.strftime('%Y%m%d')}#{ext}"
  end

  def message_content
    case message_type
    when 'text'
      @raw_message.dig(:message, :conversation) || @raw_message.dig(:message, :extendedTextMessage, :text)
    when 'image'
      @raw_message.dig(:message, :imageMessage, :caption)
    when 'video'
      @raw_message.dig(:message, :videoMessage, :caption)
    when 'reaction'
      @raw_message.dig(:message, :reactionMessage, :text)
    end
  end

  def message_id
    @raw_message[:key][:id]
  end

  def message_mimetype
    case message_type
    when 'image'
      @raw_message.dig(:message, :imageMessage, :mimetype)
    when 'sticker'
      @raw_message.dig(:message, :stickerMessage, :mimetype)
    when 'video'
      @raw_message.dig(:message, :videoMessage, :mimetype)
    when 'audio'
      @raw_message.dig(:message, :audioMessage, :mimetype)
    when 'file'
      @raw_message.dig(:message, :documentMessage, :mimetype)
    end
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

  def process_messages_update
    updates = processed_params[:data]
    updates.each do |update|
      @message = nil
      @raw_message = update
      handle_update
    end
  end

  def handle_update
    raise MessageNotFoundError unless find_message_by_source_id(message_id)

    update_status if @raw_message.dig(:update, :status).present?
    handle_edited_content if @raw_message.dig(:update, :message).present?
  end

  def update_status
    status = status_mapper
    @message.update!(status: status) if status.present? && status_transition_allowed?(status)
  end

  def status_mapper
    # NOTE: Baileys status codes vs. Chatwoot support:
    #  - (0) ERROR         → (3) failed
    #  - (1) PENDING       → (0) sent
    #  - (2) SERVER_ACK    → (0) sent
    #  - (3) DELIVERY_ACK  → (1) delivered
    #  - (4) READ          → (2) read
    #  - (5) PLAYED        → (unsupported: PLAYED)
    # For details: https://github.com/WhiskeySockets/Baileys/blob/v6.7.16/WAProto/index.d.ts#L36694
    status = @raw_message.dig(:update, :status)
    case status
    when 0
      'failed'
    when 1, 2
      'sent'
    when 3
      'delivered'
    when 4
      'read'
    when 5
      Rails.logger.warn 'Baileys unsupported message update status: PLAYED(5)'
    else
      Rails.logger.warn "Baileys unsupported message update status: #{status}"
    end
  end

  def status_transition_allowed?(new_status)
    return false if @message.status == 'read'
    return false if @message.status == 'delivered' && new_status == 'sent'

    true
  end

  def handle_edited_content
    @raw_message = @raw_message.dig(:update, :message, :editedMessage)
    content = message_content

    unless content
      Rails.logger.warn 'No valid message content found in the edit event'
      return
    end

    @message.update!(content: content, is_edited: true, previous_content: @message.content)
  end
end
