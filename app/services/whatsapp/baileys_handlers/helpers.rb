module Whatsapp::BaileysHandlers::Helpers # rubocop:disable Metrics/ModuleLength
  include Whatsapp::IncomingMessageServiceHelpers

  private

  def unwrap_ephemeral_message(msg)
    msg.key?(:ephemeralMessage) ? msg.dig(:ephemeralMessage, :message) : msg
  end

  def raw_message_id
    @raw_message[:key][:id]
  end

  def incoming?
    !@raw_message[:key][:fromMe]
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

  def message_type # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength,Metrics/AbcSize
    msg = unwrap_ephemeral_message(@raw_message[:message])
    if msg.key?(:conversation) || msg.dig(:extendedTextMessage, :text).present?
      'text'
    elsif msg.key?(:imageMessage)
      'image'
    elsif msg.key?(:audioMessage)
      'audio'
    elsif msg.key?(:videoMessage)
      'video'
    elsif msg.key?(:documentMessage) || msg.key?(:documentWithCaptionMessage)
      'file'
    elsif msg.key?(:stickerMessage)
      'sticker'
    elsif msg.key?(:reactionMessage)
      'reaction'
    elsif msg.key?(:editedMessage)
      'edited'
    elsif msg.key?(:contactMessage)
      match_phone_number = msg.dig(:contactMessage, :vcard)&.match(/waid=(\d+)/)
      match_phone_number ? 'contact' : 'unsupported'
    elsif msg.key?(:protocolMessage)
      'protocol'
    elsif msg.key?(:messageContextInfo) && msg.keys.count == 1
      'context'
    else
      'unsupported'
    end
  end

  def message_content # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
    msg = unwrap_ephemeral_message(@raw_message[:message])
    case message_type
    when 'text'
      text = msg[:conversation] || msg.dig(:extendedTextMessage, :text)
      context_info = msg.dig(:extendedTextMessage, :contextInfo)
      convert_incoming_mentions(text, context_info)
    when 'image'
      msg.dig(:imageMessage, :caption)
    when 'video'
      msg.dig(:videoMessage, :caption)
    when 'file'
      msg.dig(:documentMessage, :caption).presence ||
        msg.dig(:documentWithCaptionMessage, :message, :documentMessage, :caption)
    when 'reaction'
      msg.dig(:reactionMessage, :text)
    when 'contact'
      # FIXME: Missing specs
      display_name = msg.dig(:contactMessage, :displayName)
      vcard = msg.dig(:contactMessage, :vcard)
      match_phone_number = vcard&.match(/waid=(\d+)/)

      return display_name unless match_phone_number
      return match_phone_number[1] if display_name&.start_with?('+')

      "#{display_name} - #{match_phone_number[1]}" if match_phone_number
    end
  end

  def reply_to_message_id # rubocop:disable Metrics/CyclomaticComplexity
    msg = unwrap_ephemeral_message(@raw_message[:message])
    message_key = case message_type
                  when 'text' then :extendedTextMessage
                  when 'image' then :imageMessage
                  when 'sticker' then :stickerMessage
                  when 'audio' then :audioMessage
                  when 'video' then :videoMessage
                  when 'contact' then :contactMessage
                  when 'file'
                    context_info = msg.dig(:documentMessage, :contextInfo).presence ||
                                   msg.dig(:documentWithCaptionMessage, :message, :documentMessage, :contextInfo)
                    return context_info&.dig(:stanzaId)
                  end

    msg.dig(message_key, :contextInfo, :stanzaId) if message_key
  end

  def file_content_type
    return :image if message_type.in?(%w[image sticker])
    return :video if message_type.in?(%w[video video_note])
    return :audio if message_type == 'audio'

    :file
  end

  def message_mimetype
    msg = unwrap_ephemeral_message(@raw_message[:message])
    case message_type
    when 'image'
      msg.dig(:imageMessage, :mimetype)
    when 'sticker'
      msg.dig(:stickerMessage, :mimetype)
    when 'video'
      msg.dig(:videoMessage, :mimetype)
    when 'audio'
      msg.dig(:audioMessage, :mimetype)
    when 'file'
      msg.dig(:documentMessage, :mimetype).presence ||
        msg.dig(:documentWithCaptionMessage, :message, :documentMessage, :mimetype)
    end
  end

  def extract_from_jid(type:)
    addressing_mode = @raw_message[:key][:addressingMode]
    reference_field = addressing_mode && addressing_mode != type ? :remoteJidAlt : :remoteJid

    jid = @raw_message[:key][reference_field]
    return unless jid

    # NOTE: jid shape is `<user>_<agent>:<device>@<server>`
    # https://github.com/WhiskeySockets/Baileys/blob/v7.0.0-rc.6/src/WABinary/jid-utils.ts#L52
    jid.split('@').first.split(':').first.split('_').first
  end

  def contact_name
    # NOTE: `verifiedBizName` is only available for business accounts and has a higher priority than `pushName`.
    name = @raw_message[:verifiedBizName].presence || @raw_message[:pushName]
    return name if name.presence && (self_message? || incoming?)

    extract_from_jid(type: 'pn') || extract_from_jid(type: 'lid')
  end

  def self_message?
    normalize_phone_number(extract_from_jid(type: 'pn')) == normalize_phone_number(inbox.channel.phone_number.delete('+'))
  end

  def normalize_phone_number(phone_number)
    return unless phone_number

    Whatsapp::PhoneNormalizers::BrazilPhoneNormalizer.new.normalize(phone_number)
  end

  def ignore_message?
    message_type.in?(%w[protocol context edited]) ||
      (message_type == 'reaction' && message_content.blank?)
  end

  def fetch_profile_picture_url(phone_number)
    jid = "#{phone_number}@s.whatsapp.net"
    response = inbox.channel.provider_service.get_profile_pic(jid)
    response&.dig('data', 'profilePictureUrl')
  rescue StandardError => e
    Rails.logger.error "Failed to fetch profile picture for #{phone_number}: #{e.message}"
    nil
  end

  def try_update_contact_avatar(contact = nil)
    # TODO: Current logic will never update the contact avatar if their profile picture changes on WhatsApp.
    target_contact = contact || @contact
    return if target_contact.avatar.attached?

    phone = contact ? target_contact.phone_number&.delete('+') : extract_from_jid(type: 'pn')
    profile_pic_url = fetch_profile_picture_url(phone) if phone
    ::Avatar::AvatarFromUrlJob.perform_later(target_contact, profile_pic_url) if profile_pic_url
  end

  def message_under_process?
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{raw_message_id}")
    Redis::Alfred.get(key)
  end

  def acquire_message_processing_lock
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{raw_message_id}")
    Redis::Alfred.set(key, true, nx: true, ex: 1.day)
  end

  def clear_message_source_id_from_redis
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{raw_message_id}")
    ::Redis::Alfred.delete(key)
  end

  def convert_incoming_mentions(text, context_info)
    return text if text.blank? || context_info.blank?

    Whatsapp::MentionConverterService.convert_incoming_mentions(text, context_info, inbox.account, inbox)
  end
end
