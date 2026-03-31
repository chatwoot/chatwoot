# rubocop:disable Metrics/ClassLength
class EvolutionGo::WebhookService
  CONNECTION_EVENTS = %w[
    connected
    pairsuccess
    disconnected
    loggedout
    qrcode
    qrsuccess
    qrtimeout
    temporaryban
    connectfailure
  ].freeze

  pattr_initialize [:params!]

  def perform
    return if channel.blank?

    case normalized_event
    when 'message'
      process_message_event
    when 'receipt'
      process_receipt_event
    when *CONNECTION_EVENTS
      process_connection_event
    end
  end

  private

  def process_message_event
    normalized_message = normalized_message_payload
    return if normalized_message.blank?

    normalized_params = if message_from_me?
                          { message_echoes: [normalized_message] }
                        else
                          {
                            contacts: [normalized_contact_payload(normalized_message[:from])],
                            messages: [normalized_message]
                          }
                        end

    Whatsapp::IncomingMessageEvolutionGoService.new(
      inbox: channel.inbox,
      params: normalized_params.with_indifferent_access,
      outgoing_echo: message_from_me?
    ).perform
  end

  def process_receipt_event
    status = receipt_status
    return unless %w[delivered read].include?(status)

    receipt_message_ids.each do |message_id|
      message = channel.inbox.messages.find_by(source_id: message_id.to_s)
      next if message.blank?

      Messages::StatusUpdateService.new(message, status).perform
    end
  end

  def process_connection_event
    EvolutionGo::SyncStateService.new(channel: channel, payload: payload).perform

    if %w[loggedout temporaryban connectfailure].include?(normalized_event)
      channel.prompt_reauthorization!
    elsif %w[connected pairsuccess].include?(normalized_event)
      channel.reauthorized!
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def normalized_message_payload
    remote_jid = extract_jid
    return if remote_jid.blank? || remote_jid.end_with?('@g.us', '@broadcast')
    return if extract_message_id.blank?

    number = extract_number(remote_jid)
    message_type = normalized_message_type
    return if number.blank? || message_type.blank?
    return if message_type == 'text' && message_text.blank?

    payload = {
      id: extract_message_id.to_s,
      type: message_type
    }
    payload[message_from_me? ? :to : :from] = number
    payload[:context] = { id: quoted_message_id } if quoted_message_id.present?

    if message_type == 'text'
      payload[:text] = { body: message_text.to_s }
    else
      payload[message_type.to_sym] = attachment_payload(message_type)
    end

    payload.with_indifferent_access
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def normalized_contact_payload(number)
    {
      wa_id: number,
      profile: {
        name: push_name.presence || "+#{number}"
      }
    }.with_indifferent_access
  end

  # rubocop:disable Metrics/AbcSize
  def attachment_payload(message_type)
    source = attachment_source(message_type)

    {
      caption: message_text.presence || source[:caption].presence,
      media_url: raw_message[:mediaUrl].presence || source[:mediaUrl].presence || source[:url].presence,
      base64: raw_message[:base64].presence || source[:base64].presence,
      mimetype: raw_message[:mimetype].presence || source[:mimetype].presence,
      filename: source[:fileName].presence || source[:filename].presence
    }.compact.with_indifferent_access
  end
  # rubocop:enable Metrics/AbcSize

  def attachment_source(message_type)
    raw_message[attachment_key_for(message_type)].to_h.with_indifferent_access
  end

  def attachment_key_for(message_type)
    {
      'image' => :imageMessage,
      'video' => :videoMessage,
      'audio' => :audioMessage,
      'document' => :documentMessage,
      'sticker' => :stickerMessage
    }[message_type]
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def normalized_message_type
    return 'text' if raw_message[:conversation].present? || raw_message.dig(:extendedTextMessage, :text).present?
    return 'image' if raw_message[:imageMessage].present?
    return 'video' if raw_message[:videoMessage].present?
    return 'audio' if raw_message[:audioMessage].present?
    return 'document' if raw_message[:documentMessage].present?
    return 'sticker' if raw_message[:stickerMessage].present?

    nil
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def message_text
    raw_message[:conversation].presence ||
      raw_message.dig(:extendedTextMessage, :text).presence ||
      raw_message.dig(:imageMessage, :caption).presence ||
      raw_message.dig(:videoMessage, :caption).presence ||
      raw_message.dig(:documentMessage, :caption).presence
  end

  def message_from_me?
    payload.dig(:data, :key, :fromMe) || payload.dig(:data, :Info, :IsFromMe) || false
  end

  def extract_message_id
    payload.dig(:data, :key, :id) || payload.dig(:data, :Info, :ID)
  end

  def extract_jid
    jid = payload.dig(:data, :key, :remoteJid) || payload.dig(:data, :Info, :Chat)
    return "#{jid[:User]}@#{jid[:Server]}" if jid.is_a?(Hash) && jid[:User].present? && jid[:Server].present?

    jid.to_s
  end

  def extract_number(jid)
    jid.to_s.split('@').first.to_s.split(':').first.to_s.gsub(/\D/, '')
  end

  def quoted_message_id
    payload.dig(:data, :quoted, :stanzaID) ||
      raw_message.dig(:extendedTextMessage, :contextInfo, :stanzaID) ||
      raw_message.dig(:imageMessage, :contextInfo, :stanzaID) ||
      raw_message.dig(:videoMessage, :contextInfo, :stanzaID) ||
      raw_message.dig(:documentMessage, :contextInfo, :stanzaID) ||
      raw_message.dig(:audioMessage, :contextInfo, :stanzaID)
  end

  def receipt_status
    case payload[:state].to_s.downcase
    when 'read', 'readself'
      'read'
    when 'delivered'
      'delivered'
    end
  end

  def receipt_message_ids
    ids = payload.dig(:data, :MessageIDs) ||
          payload.dig(:data, :messageIDs) ||
          payload.dig(:data, :messageIds) ||
          [payload.dig(:data, :MessageID)].compact

    Array(ids).compact
  end

  def push_name
    payload.dig(:data, :PushName) || payload.dig(:data, :pushName)
  end

  def normalized_event
    payload[:event].to_s.downcase
  end

  def raw_message
    @raw_message ||= begin
      raw_payload = payload.dig(:data, :Message) || payload.dig(:data, :message)
      raw_payload.to_h.with_indifferent_access
    end
  end

  def channel
    @channel ||= begin
      instance_name = payload[:instanceName].presence || payload[:instance].presence
      Channel::Whatsapp.where(provider: 'evolution_go')
                       .find_by("provider_config ->> 'instance_name' = ?", instance_name)
    end
  end

  def payload
    @payload ||= params.with_indifferent_access
  end
end
# rubocop:enable Metrics/ClassLength
