module AudioTranscodable
  extend ActiveSupport::Concern

  included do
    # Prepended so set_extension and the Active Storage save callbacks see the MP3, not the original.
    before_save :transcode_inbound_audio, prepend: true
  end

  private

  # Every channel stores inbound audio through Attachment, so converting here covers WhatsApp Cloud,
  # Twilio, Telegram, the widget and the API alike. Reassigning self.file swaps the pending blob
  # before anything is persisted or uploaded; the original is kept whenever conversion fails.
  def transcode_inbound_audio
    attachable = attachment_changes['file']&.attachable
    return if attachable.nil? || !audio? || !audio_from_contact_channel?

    io, filename, content_type, source_blob = pending_audio_source(attachable)
    return if io.nil?

    result = Audio::TranscoderService.new(io: io, filename: filename, content_type: content_type).perform
    return unless result[:transcoded]

    self.file = { io: result[:io], filename: result[:filename], content_type: result[:content_type] }
    self.extension = nil
    purge_orphaned_source(source_blob)
  end

  # A direct upload blob is attached to nothing after the swap. A blob reused from another
  # attachment (forwarding) still belongs to that one and must stay.
  def purge_orphaned_source(blob)
    return if blob.nil? || blob.attachments.exists?

    blob.purge_later
  end

  # Incoming messages, plus echoes of messages sent from the phone app (WhatsApp coexistence).
  # Echoes are created as delivered with the provider's source_id, so they are never sent again.
  # Agent replies stay untouched: WhatsApp needs them as Ogg/Opus to show them as voice notes.
  def audio_from_contact_channel?
    return false if message.nil?
    return true if message.incoming?

    message.outgoing? && message.delivered? && message.source_id.present?
  end

  # Returns [io, filename, content_type, source_blob], or [] when the pending attachable is not an
  # Ogg candidate or cannot be read. source_blob is only set for direct uploads, so the orphaned
  # original can be purged after the swap.
  def pending_audio_source(attachable)
    case attachable
    when Hash
      [attachable[:io], attachable[:filename].to_s, attachable[:content_type].to_s, nil]
    when ActiveStorage::Blob
      blob_audio_source(attachable)
    when String
      blob = ActiveStorage::Blob.find_signed(attachable)
      blob ? blob_audio_source(blob) : []
    else
      readable_audio_source(attachable)
    end
  rescue StandardError
    []
  end

  def blob_audio_source(blob)
    probe = Audio::TranscoderService.new(io: nil, filename: blob.filename.to_s, content_type: blob.content_type)
    return [] unless probe.transcodable?

    [StringIO.new(blob.download), blob.filename.to_s, blob.content_type.to_s, blob]
  end

  def readable_audio_source(attachable)
    return [] unless attachable.respond_to?(:read)

    [attachable, attachable.try(:original_filename).to_s, attachable.try(:content_type).to_s, nil]
  end
end
