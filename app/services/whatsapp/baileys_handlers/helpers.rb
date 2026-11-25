module Whatsapp::BaileysHandlers::Helpers # rubocop:disable Metrics/ModuleLength
  include Whatsapp::IncomingMessageServiceHelpers

  private

  # WhatsApp nests the real payload inside wrapper nodes: ephemeralMessage
  # (disappearing chats), associatedChildMessage (album items) and
  # lottieStickerMessage (animated stickers). Wrappers can nest, so unwrap
  # until the content surfaces (iteration bound mirrors Baileys'
  # normalizeMessageContent).
  MESSAGE_WRAPPER_KEYS = %i[ephemeralMessage associatedChildMessage lottieStickerMessage].freeze

  # The servers a phone-addressed jid lives on, `c.us` being the legacy form. The same
  # pair `jid_type` reads as a `user` chat.
  PHONE_JID_SERVERS = %w[s.whatsapp.net c.us].freeze
  LID_JID_SERVER = 'lid'.freeze

  # An upsert entry can carry no message at all (a view-once message, which WhatsApp does
  # not deliver to linked devices), so a missing one reads as empty rather than raising.
  def unwrap_message_content(msg)
    msg ||= {}
    5.times do
      wrapper_key = MESSAGE_WRAPPER_KEYS.find { |key| msg.key?(key) }
      break unless wrapper_key

      msg = msg.dig(wrapper_key, :message) || {}
    end
    msg
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
    msg = unwrap_message_content(@raw_message[:message])
    # Nothing but the key arrived. For view-once that is WhatsApp withholding the content
    # from linked devices, and the agent still has to learn something was sent.
    return @raw_message.dig(:key, :isViewOnce) ? 'view_once' : 'empty' if msg.blank?

    # A Click-to-WhatsApp ad-click can arrive as an extendedTextMessage carrying
    # only the ad context (no text). Classify it as text so it renders with the
    # ad headline/body as fallback content instead of being dropped/unsupported.
    if msg.key?(:conversation) || msg.dig(:extendedTextMessage, :text).present? ||
       msg.dig(:extendedTextMessage, :contextInfo, :externalAdReply).present?
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
    elsif msg.key?(:contactsArrayMessage)
      'contact'
    elsif msg.key?(:locationMessage) || msg.key?(:liveLocationMessage)
      'location'
    elsif msg.key?(:protocolMessage)
      'protocol'
    elsif msg.key?(:secretEncryptedMessage)
      'secret'
    elsif msg.key?(:albumMessage)
      'album'
    # WhatsApp withholds authentication-template messages (verification codes) from
    # linked devices and delivers a placeholder in their place, so the content never
    # reaches the connector. Classified apart from `unsupported` because there is
    # nothing to parse here: the bubble has to explain the masking, not a missing type.
    elsif msg.key?(:placeholderMessage)
      'masked'
    elsif msg.key?(:messageContextInfo) && msg.keys.count == 1
      'context'
    elsif Whatsapp::Baileys::RichMessageParser.rich?(msg)
      'rich'
    else
      'unsupported'
    end
  end

  def message_content # rubocop:disable Metrics/CyclomaticComplexity
    msg = unwrap_message_content(@raw_message[:message])
    case message_type
    when 'text'
      text = msg[:conversation] || msg.dig(:extendedTextMessage, :text)
      context_info = msg.dig(:extendedTextMessage, :contextInfo)
      text = baileys_referral_fallback_content(context_info) if text.blank?
      convert_incoming_mentions(text, context_info)
    when 'image'
      msg.dig(:imageMessage, :caption)
    when 'video'
      msg.dig(:videoMessage, :caption)
    when 'file'
      msg.dig(:documentMessage, :caption).presence ||
        msg.dig(:documentWithCaptionMessage, :message, :documentMessage, :caption)
    when 'rich'
      Whatsapp::Baileys::RichMessageParser.to_text(Whatsapp::Baileys::RichMessageParser.new(msg).parse)
    when 'reaction'
      msg.dig(:reactionMessage, :text)
    end
  end

  # The shared contacts of the current message: the entries of a
  # contactsArrayMessage, or the single contactMessage wrapped in an array.
  def baileys_contacts
    msg = unwrap_message_content(@raw_message[:message])
    msg.dig(:contactsArrayMessage, :contacts).presence || [msg[:contactMessage]].compact
  end

  # Extracts { phone, name } from a Baileys contact hash. The vcard TEL line is
  # `...;waid=<digits>:<formatted phone>`, so prefer the formatted phone and fall
  # back to the waid digits.
  def baileys_contact_fields(contact)
    vcard = contact&.dig(:vcard).to_s
    phone = vcard[/waid=\d+:\s*([^\r\n]+)/, 1]&.strip
    phone = vcard[/waid=(\d+)/, 1] if phone.blank?
    { phone: phone, name: contact&.dig(:displayName) }
  end

  # Short "Name - phone" line used as the message content (chat-list preview).
  def baileys_contact_line(contact)
    fields = baileys_contact_fields(contact)
    return fields[:name] if fields[:phone].blank?
    return fields[:phone] if fields[:name].blank? || fields[:name].start_with?('+')

    "#{fields[:name]} - #{fields[:phone]}"
  end

  # The provider id of the quoted message (stanzaId), read from the same per-type
  # contextInfo used for ad attribution, so every supported type (incl. rich,
  # location and contact) resolves replies through a single lookup.
  def reply_to_message_id
    message_context_info&.dig(:stanzaId)
  end

  # Returns the `contextInfo` for the current message type, where the
  # Click-to-WhatsApp ad metadata (`externalAdReply`) lives.
  def message_context_info # rubocop:disable Metrics/CyclomaticComplexity
    msg = unwrap_message_content(@raw_message[:message])
    case message_type
    when 'text' then msg.dig(:extendedTextMessage, :contextInfo)
    when 'image' then msg.dig(:imageMessage, :contextInfo)
    when 'video' then msg.dig(:videoMessage, :contextInfo)
    when 'audio' then msg.dig(:audioMessage, :contextInfo)
    when 'sticker' then msg.dig(:stickerMessage, :contextInfo)
    when 'file'
      msg.dig(:documentMessage, :contextInfo).presence ||
        msg.dig(:documentWithCaptionMessage, :message, :documentMessage, :contextInfo)
    when 'contact'
      msg.dig(:contactMessage, :contextInfo) || msg.dig(:contactsArrayMessage, :contextInfo)
    when 'location'
      msg.dig(:locationMessage, :contextInfo) || msg.dig(:liveLocationMessage, :contextInfo)
    when 'rich' then Whatsapp::Baileys::RichMessageParser.new(msg).context_info
    end
  end

  def baileys_referral_fallback_content(context_info)
    ad = context_info&.dig(:externalAdReply)
    return if ad.blank?

    ad[:title].presence || ad[:body].presence
  end

  # Media nested in a rich header (e.g. a PDF/image in a template header), or nil.
  def rich_media_header
    return unless message_type == 'rich'

    Whatsapp::Baileys::RichMessageParser.new(unwrap_message_content(@raw_message[:message])).media_header
  end

  def file_content_type
    return :image if message_type.in?(%w[image sticker])
    return :video if message_type.in?(%w[video video_note])
    return :audio if message_type == 'audio'
    return rich_media_header[:kind].to_sym if rich_media_header

    :file
  end

  def message_mimetype # rubocop:disable Metrics/CyclomaticComplexity
    msg = unwrap_message_content(@raw_message[:message])
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
    when 'rich'
      rich_media_header&.dig(:node, :mimetype)
    end
  end

  def extract_from_jid(type:)
    addressing_mode = @raw_message[:key][:addressingMode]
    reference_field = addressing_mode && addressing_mode != type ? :remoteJidAlt : :remoteJid

    jid = @raw_message[:key][reference_field]
    return unless jid
    return phone_from_jid(jid) if type == 'pn'

    jid_user(jid)
  end

  # The account a jid names, without the device and agent suffixes.
  # NOTE: jid shape is `<user>_<agent>:<device>@<server>`
  # https://github.com/WhiskeySockets/Baileys/blob/v7.0.0-rc.6/src/WABinary/jid-utils.ts#L52
  def jid_user(jid)
    jid.split('@').first.split(':').first.split('_').first
  end

  # The phone number a jid carries, or nothing when the jid is not a phone address.
  # A LID is digits too, so `235085806727321@lid` reads as a phone number to anything
  # that looks only at the part before the `@`: the server is the one thing that tells
  # them apart. Live messages name the pair (`addressingMode` plus an alt jid) and the
  # question rarely comes up, but a history message is raw protobuf -- four fields, no
  # addressing mode -- so its chat arrives addressed by LID alone, and reading that as
  # a phone number is how a contact ends up with `+235085806727321`.
  def phone_from_jid(jid)
    jid_user_on(jid, PHONE_JID_SERVERS)
  end

  # The LID a jid carries, asked the same way and for the same reason.
  def lid_from_jid(jid)
    jid_user_on(jid, [LID_JID_SERVER])
  end

  def jid_user_on(jid, servers)
    return if jid.blank?
    return unless jid.split('@').last.in?(servers)

    user = jid_user(jid)
    user if user.match?(/\A\d+\z/)
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

  # A name equal to the contact's WhatsApp phone (in any normalized "9"-variant),
  # its LID, or the "<lid>@lid" identifier is an auto-generated placeholder rather
  # than a human-entered name. Matching normalized phone variants lets the real
  # pushName replace a number stranded by phone normalization, e.g. when the
  # Brazilian "9" digit is added/removed and phone_number no longer matches the
  # digits saved as the name.
  def placeholder_contact_name?(name, phone:, identifier:)
    return true if name.blank?
    return true if name == identifier

    digits = name.delete('+')
    return false unless digits.match?(/\A\d+\z/)

    lid = identifier&.delete_suffix('@lid')
    return true if digits.in?([phone, lid].compact)

    phone.present? && same_whatsapp_number?(digits, phone)
  end

  def same_whatsapp_number?(left, right)
    normalizer = phone_normalizer_for(left) || phone_normalizer_for(right)
    return false unless normalizer

    normalizer.normalize(left) == normalizer.normalize(right)
  end

  def phone_normalizer_for(value)
    Whatsapp::PhoneNumberNormalizationService::NORMALIZERS
      .map(&:new)
      .find { |normalizer| normalizer.handles_country?(value) }
  end

  # An albumMessage is only the marker announcing a media group; each item
  # arrives as its own associatedChildMessage upsert, so the marker itself
  # renders nothing.
  #
  # A secretEncryptedMessage is an edit of an existing message, encrypted under
  # that message's secret. The provider is the only side that can decrypt it and
  # it delivers the result as a messages.update; anything still arriving here is
  # a blob we have no key for, and rendering it as an unsupported message is
  # worse than dropping it.
  def ignore_message?
    message_type.in?(%w[protocol context edited album secret empty])
  end

  # A protocolMessage of type REVOKE is the contact deleting a message for everyone.
  # Baileys delivers it as a messages.upsert entry whose protocolMessage.key.id
  # points at the original message.
  def protocol_revoke?
    unwrap_message_content(@raw_message[:message]).dig(:protocolMessage, :type) == 'REVOKE'
  end

  def protocol_revoke_target_id
    unwrap_message_content(@raw_message[:message]).dig(:protocolMessage, :key, :id)
  end

  def reaction_removal?
    message_type == 'reaction' && message_content.blank?
  end

  # Baileys doesn't set @in_reply_to_external_id before set_conversation (it's
  # written later in build_message_content_attributes), so read the target id
  # straight from the raw reaction webhook here.
  def reaction_target_external_id
    unwrap_message_content(@raw_message[:message]).dig(:reactionMessage, :key, :id)
  end

  def try_update_contact_avatar(contact = nil)
    # TODO: Current logic will never update the contact avatar if their profile picture changes on WhatsApp.
    target_contact = contact || @contact
    return if target_contact.avatar.attached?

    phone = contact ? target_contact.phone_number&.delete('+') : extract_from_jid(type: 'pn')
    return if phone.blank?

    Channels::Whatsapp::BaileysUpdateContactAvatarJob.perform_later(target_contact, inbox, phone)
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
