# The body of one message from this provider, turned into canonical content.
#
# Discrimination is on `messageType` alone. `type` is the provider's own coarse grouping
# and lies about the interesting cases: a location message is `type: "text"` and a shared
# contact is `type: "media"`.
class Whatsapp::Session::Backends::Uazapi::ContentMapper
  TEXT_TYPES = %w[Conversation ExtendedTextMessage].freeze
  MEDIA_KINDS = {
    'ImageMessage' => 'image', 'VideoMessage' => 'video', 'AudioMessage' => 'audio',
    'DocumentMessage' => 'document', 'StickerMessage' => 'sticker'
  }.freeze

  attr_reader :message

  def initialize(message)
    @message = message
  end

  def perform
    type = message[:messageType].to_s

    return model::Content::Text.new(body: message[:text].to_s) if TEXT_TYPES.include?(type)
    return media(MEDIA_KINDS[type]) if MEDIA_KINDS.key?(type)
    return location if type == 'LocationMessage'
    return contacts if type == 'ContactMessage'

    model::Content::Unsupported.new(reason: 'unknown_type')
  end

  # A plain text message carries `content` as the string itself; everything else carries
  # the protobuf body as an object. Read as an object either way, so a caller never has to
  # ask which one it got.
  def body
    content = message[:content]
    content.is_a?(Hash) ? content : {}.with_indifferent_access
  end

  private

  def model = Whatsapp::Session::Model

  # The URL in the payload is the encrypted blob on WhatsApp's CDN and cannot be fetched
  # without the message's media key, so the reference is the message itself: the backend
  # asks the provider to decrypt it and hands back a link that can be downloaded.
  #
  # The thumbnail is deliberately dropped. It is base64 in the body, nothing renders it,
  # and it would ride along in every job argument for the whole retry ladder.
  def media(kind)
    model::Content::Media.new(
      kind: kind, mime: mime, filename: body[:fileName].presence,
      caption: body[:caption].presence || message[:text].presence,
      voice_note: body[:PTT].present? || message[:mediaType] == 'ptt',
      size: body[:fileLength], duration: body[:seconds], ref: media_ref
    )
  end

  def media_ref
    model::MediaRef.new(
      kind: 'uazapi_message', id: message[:messageid], mime: mime,
      size: body[:fileLength], sha256: body[:fileSHA256].presence
    )
  end

  def mime = body[:mimetype].presence

  def location
    model::Content::Location.new(
      latitude: body[:degreesLatitude], longitude: body[:degreesLongitude],
      name: body[:name].presence, address: body[:address].presence
    )
  end

  # One card per message on this provider, which the writer stores as its own row.
  def contacts
    model::Content::Contacts.new(
      contacts: [{ 'display_name' => body[:displayName].presence, 'vcard' => body[:vcard].presence }.compact]
    )
  end
end
