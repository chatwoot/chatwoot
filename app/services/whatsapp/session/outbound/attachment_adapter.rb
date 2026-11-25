# Turns a Chatwoot attachment into canonical media content.
#
# The bytes are not read here: the provider is given a URL and fetches them itself.
# That keeps a 60 MB video out of the Rails process and out of the command frame, and
# it is why an inbox behind a private network needs INTERNAL_HOST_URL to point at
# something the provider can actually reach.
class Whatsapp::Session::Outbound::AttachmentAdapter
  # Chatwoot's file_type enum, in the terms the WhatsApp protocol uses.
  KINDS = { 'image' => 'image', 'audio' => 'audio', 'video' => 'video', 'file' => 'document' }.freeze

  SCHEME = %r{\A[a-z][a-z0-9+.-]*://}i
  AUTHORITY = %r{\A[a-z][a-z0-9+.-]*://[^/]+}i

  attr_reader :attachment, :caption, :channel

  def initialize(attachment, caption: nil, channel: nil)
    @attachment = attachment
    @caption = caption
    @channel = channel
  end

  # Resolved per call rather than aliased: a constant pointing at another file's class
  # keeps the pre-reload object, and in development that object is the one Zeitwerk
  # already discarded.
  def content = Whatsapp::Session::Model::Content
  def media_ref = Whatsapp::Session::Model::MediaRef

  # `download_url` is built from Rails' default url options, which are the public
  # FRONTEND_URL. That is the right address for a provider reaching Rails over the
  # internet and the wrong one for a connector sitting next to it on a private network,
  # so the host is swapped for the internal one where the inbox says to use it.
  #
  # Only for a URL this app serves, which is not every blob: with a cloud storage service
  # `download_url` is a presigned URL answered by S3 or GCS, whose path means nothing to
  # Rails and whose signature is bound to the host it was made for. Moving that one to the
  # internal host turns every outbound attachment into a 404, so it is left alone: a
  # storage service reachable over the internet needs no internal address anyway.
  def media_url
    url = attachment.download_url
    internal = ENV.fetch('INTERNAL_HOST_URL', nil)
    return url unless channel&.use_internal_host? && internal.present? && app_hosted?(url)

    url.sub(AUTHORITY, internal.chomp('/'))
  end

  def perform
    return if attachment.blank? || !attachment.file.attached?

    # Resolved first, because `download_url` also rewrites the blob of an `.ogg` recorded
    # as `audio/opus` to `audio/ogg`. Reading the type before it leaves the command
    # advertising two different ones, and WhatsApp classifies a voice note by that type.
    url = media_url
    file = attachment.file
    content::Media.new(
      kind: kind, mime: file.content_type, filename: file.filename.to_s, caption: caption.presence,
      voice_note: voice_note?, video_note: video_note, size: file.byte_size,
      ref: media_ref.url(url, mime: file.content_type, size: file.byte_size),
      **measurements
    )
  end

  private

  # What the recipient's client lays the bubble out from before a byte of the file has
  # arrived. Without them the conversation jumps when the media lands, and the note that
  # every other bubble draws bars for arrives with a flat one.
  #
  # All of it read from what ActiveStorage already analysed, except the waveform, which no
  # analyser produces. Absent stays absent: a deployment without ffprobe has no dimensions
  # to give, and a zero on the wire is a measurement of nothing while an absent field is
  # what every client already handles.
  def analysis
    @analysis ||= (attachment.file.blob.metadata || {}).with_indifferent_access
  end

  # Seconds, which is what the contract types. A recording of less than half a second is
  # the one case rounding sends to zero, and zero is a duration the bubble would draw as
  # an empty track, so it keeps the shortest value it can mean.
  # Gathered in one place so `perform` stays a description of the frame rather than of how
  # each field is found, and so an absent measurement drops out of the payload instead of
  # travelling as a null.
  def measurements
    { duration: duration, waveform: waveform }.compact.merge(picture_size)
  end

  def duration
    return unless %w[audio video].include?(kind)

    seconds = analysis[:duration]
    return if seconds.blank?

    [seconds.to_f.round, 1].max
  end

  # Both sides or neither, which is what the connector refuses on: half a size lays out
  # nothing, and the two only ever come from the same analysis anyway. Never on audio or a
  # document, which have no picture to size.
  def picture_size
    return {} unless %w[image video sticker].include?(kind)

    sides = [analysis[:width], analysis[:height]].map { |side| side.presence.to_i }
    return {} unless sides.all?(&:positive?)

    { width: sides.first, height: sides.last }
  end

  # Only for a note somebody recorded. A music file sent as an attachment is played from a
  # track, not from a row of bars, so measuring it would cost the decode and change nothing
  # on screen.
  def waveform
    return unless kind == 'audio' && voice_note?

    Whatsapp::Session::Outbound::Waveform.for(attachment)
  end

  # Compared against the same default url options `download_url` builds app-hosted URLs
  # from (it seeds ActiveStorage::Current.url_options with them), so the two can never
  # disagree about what "this app" is.
  def app_hosted?(url)
    host = authority(url)
    host.present? && host == authority(Rails.application.routes.default_url_options[:host])
  end

  def authority(value)
    value.to_s.sub(SCHEME, '').split('/').first
  end

  # A sticker is stored as an image with a webp body; WhatsApp needs the distinction.
  def kind
    return 'sticker' if attachment.file.content_type == 'image/webp'

    KINDS.fetch(attachment.file_type, 'document')
  end

  # Absent rather than false when it does not apply: the contract omits the flag unless it is true.
  def video_note
    true if attachment.video_note?
  end

  # `is_recorded_audio` is the older fazer.ai key (transcode pipeline and old messages).
  def voice_note?
    meta = attachment.meta || {}
    meta['is_voice_message'].present? || meta['is_recorded_audio'].present?
  end
end
