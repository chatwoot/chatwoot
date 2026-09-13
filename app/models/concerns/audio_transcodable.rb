module AudioTranscodable
  extend ActiveSupport::Concern

  included do
    # Run before set_extension so the stored extension reflects the transcoded (mp3) file.
    before_save :transcode_inbound_audio, prepend: true
  end

  private

  # Single chokepoint: every inbound channel ultimately attaches audio here, so transcoding
  # OGG/Opus -> MP3 once, pre-persist, covers them all. Reassigning self.file swaps the pending
  # blob so the MP3 is stored and the original is never persisted. Handles channel downloads
  # (Hash/IO) and direct-upload / API messages (an ActiveStorage blob or signed blob id). See #13210.
  def transcode_inbound_audio
    return unless audio? && message&.incoming?

    io, filename, content_type, source_blob = pending_source(attachment_changes['file']&.attachable)
    return if io.nil?

    swap_in_transcoded_audio(io, filename, content_type, source_blob)
  end

  def swap_in_transcoded_audio(io, filename, content_type, source_blob)
    result = Audio::TranscoderService.new(io: io, filename: filename, content_type: content_type).perform
    return unless result[:transcoded]

    self.file = { io: result[:io], filename: result[:filename], content_type: result[:content_type] }
    # A direct-upload source blob is now unattached; drop it so it doesn't leak in storage.
    source_blob&.purge_later
  end

  # Returns [io, filename, content_type, source_blob] for the pending attachable, or [] when no
  # readable source can be produced. source_blob is set only for direct-upload attachables so the
  # caller can purge the now-orphaned original after the swap.
  def pending_source(attachable)
    case attachable
    when Hash
      [attachable[:io], attachable[:filename].to_s, attachable[:content_type].to_s, nil]
    when ActiveStorage::Blob
      blob_source(attachable)
    when String
      blob = ActiveStorage::Blob.find_signed(attachable)
      blob ? blob_source(blob) : []
    else
      readable_source(attachable)
    end
  rescue StandardError
    []
  end

  def blob_source(blob)
    [StringIO.new(blob.download), blob.filename.to_s, blob.content_type.to_s, blob]
  end

  def readable_source(attachable)
    return [] unless attachable.respond_to?(:read)

    [attachable, attachable.try(:original_filename).to_s, attachable.try(:content_type).to_s, nil]
  end
end
