class Voice::Provider::Twilio::RecordingAttachmentService
  DEFAULT_FILENAME_EXTENSION = 'wav'.freeze

  pattr_initialize [:call!, :recording_sid!, :recording_url!, { recording_duration: nil }]

  def perform # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    Rails.logger.info(
      "VOICE_RECORDING_ATTACHMENT_SERVICE start call_id=#{call.id} recording_sid=#{recording_sid} url=#{recording_url}"
    )

    if recording_sid.blank? || recording_url.blank?
      Rails.logger.info('VOICE_RECORDING_ATTACHMENT_SERVICE skip reason=blank_payload')
      return
    end

    if already_attached?
      Rails.logger.info("VOICE_RECORDING_ATTACHMENT_SERVICE skip reason=already_attached call_id=#{call.id}")
      return
    end

    Rails.logger.info(
      "VOICE_RECORDING_ATTACHMENT_SERVICE downloading call_id=#{call.id} url=#{recording_url} account_sid_present=#{account_sid.present?}"
    )
    recording_file = download_recording
    Rails.logger.info(
      "VOICE_RECORDING_ATTACHMENT_SERVICE downloaded call_id=#{call.id} size=#{recording_file&.size} " \
      "content_type=#{recording_content_type(recording_file)}"
    )

    persist_recording!(recording_file)
    Rails.logger.info(
      "VOICE_RECORDING_ATTACHMENT_SERVICE persisted call_id=#{call.id} attached=#{call.reload.recording.attached?} " \
      "message_id=#{call.message_id}"
    )

    # Bump the message updated_at so the message.updated dispatcher rebroadcasts
    # the embedded Call payload (now with recording_url) to connected clients.
    call.message&.touch # rubocop:disable Rails/SkipsModelValidations
  rescue StandardError => e
    Rails.logger.error(
      "VOICE_RECORDING_ATTACHMENT_SERVICE error call_id=#{call.id} class=#{e.class} message=#{e.message}"
    )
    raise
  ensure
    recording_file.close! if recording_file.respond_to?(:close!)
  end

  private

  def persist_recording!(recording_file)
    call.with_lock do
      next if already_attached?

      attach_recording!(recording_file)
      call.recording_sid = recording_sid
      call.duration_seconds ||= normalized_recording_duration
      call.save!
    end
  end

  def already_attached?
    call.recording.attached? && call.recording_sid.to_s == recording_sid.to_s
  end

  def download_recording
    Down.download(recording_url, http_basic_authentication: [account_sid, auth_token])
  end

  def attach_recording!(recording_file)
    call.recording.attach(
      io: recording_file,
      filename: recording_filename(recording_file),
      content_type: recording_content_type(recording_file)
    )
  end

  def normalized_recording_duration
    return if recording_duration.blank?

    recording_duration.to_i
  end

  def recording_filename(recording_file)
    filename = recording_file.original_filename if recording_file.respond_to?(:original_filename)
    return filename if filename.present?

    "call-recording-#{recording_sid}.#{recording_extension(recording_file)}"
  end

  def recording_extension(recording_file)
    content_type = recording_content_type(recording_file)
    Rack::Mime::MIME_TYPES.invert[content_type].to_s.delete_prefix('.').presence || DEFAULT_FILENAME_EXTENSION
  end

  def recording_content_type(recording_file)
    recording_file.content_type.presence || 'audio/wav'
  end

  def account_sid
    @account_sid ||= channel.account_sid
  end

  def auth_token
    @auth_token ||= channel.auth_token
  end

  def channel
    @channel ||= call.inbox.channel
  end
end
