# An outgoing file on its way to WhatsApp. Backends need either a URL the provider can
# fetch (`native`, which downloads it from Rails) or the bytes themselves (`uazapi`, which
# takes base64), so both are exposed and the backend picks.
class Whatsapp::Session::Model::Attachment < Data.define(:url, :mime, :filename, :size, :kind, :voice_note, :duration)
  include Whatsapp::Session::Model::Serializable
  defaults kind: 'document', voice_note: false

  # Chatwoot's attachment file_type -> the WhatsApp media kind.
  FILE_TYPE_KINDS = {
    'image' => 'image',
    'video' => 'video',
    'audio' => 'audio',
    'file' => 'document'
  }.freeze

  def initialize(**attributes)
    kind = (attributes[:kind] || 'document').to_s
    unless Whatsapp::Session::Model::Content::Media::KINDS.include?(kind)
      raise Whatsapp::Session::Errors::InvalidPayload, "unknown attachment kind: #{kind}"
    end

    super(**attributes, kind: kind)
  end

  def to_content(caption: nil)
    Whatsapp::Session::Model::Content::Media.new(
      kind: kind, mime: mime, filename: filename, caption: caption, voice_note: voice_note,
      size: size, duration: duration, ref: Whatsapp::Session::Model::MediaRef.url(url, mime: mime, size: size)
    )
  end
end
