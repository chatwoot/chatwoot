module AudioTranscodable
  extend ActiveSupport::Concern

  included do
    # Run before set_extension so the stored extension reflects the transcoded (mp3) file.
    before_save :transcode_inbound_audio, prepend: true
  end

  private

  # Single chokepoint: every inbound channel ultimately attaches audio here, so transcoding
  # OGG/Opus → MP3 once, pre-persist, covers them all. Reassigning self.file swaps the pending
  # blob so the MP3 is what gets stored and the original is never persisted. See issue #13210.
  def transcode_inbound_audio
    return unless audio? && message&.incoming?

    change = attachment_changes['file']
    return if change.blank?

    attachable = change.attachable
    io = pending_io(attachable)
    return if io.nil?

    result = Audio::TranscoderService.new(
      io: io,
      filename: pending_filename(attachable),
      content_type: pending_content_type(attachable)
    ).perform
    return unless result[:transcoded]

    self.file = { io: result[:io], filename: result[:filename], content_type: result[:content_type] }
  end

  def pending_io(attachable)
    return attachable[:io] if attachable.is_a?(Hash)

    attachable.respond_to?(:read) ? attachable : nil
  end

  def pending_filename(attachable)
    return attachable[:filename].to_s if attachable.is_a?(Hash)

    attachable.respond_to?(:original_filename) ? attachable.original_filename.to_s : ''
  end

  def pending_content_type(attachable)
    return attachable[:content_type].to_s if attachable.is_a?(Hash)

    attachable.respond_to?(:content_type) ? attachable.content_type.to_s : ''
  end
end
