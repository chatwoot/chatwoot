class Voice::Provider::Twilio::RecordingAttachmentService
  DEFAULT_FILENAME_EXTENSION = 'wav'.freeze

  pattr_initialize [:conversation!, :recording_sid!, :recording_url!, { recording_duration: nil }]

  def perform
    return if recording_sid.blank? || recording_url.blank?

    message = voice_call_message
    return if message.blank? || recording_already_attached?(message)

    recording_file = download_recording

    message.reload.with_lock do
      next if recording_already_attached?(message)

      attach_recording!(message, recording_file)
      update_recording_metadata!(message)
    end
  ensure
    recording_file.close! if recording_file.respond_to?(:close!)
  end

  private

  def voice_call_message
    @voice_call_message ||= conversation.messages.voice_calls.order(created_at: :desc).first
  end

  def recording_already_attached?(message)
    message.content_attributes
           &.dig('data', 'meta', 'recording', 'sid')
           .to_s == recording_sid.to_s
  end

  def download_recording
    Down.download(recording_url, http_basic_authentication: [account_sid, auth_token])
  end

  def attach_recording!(message, recording_file)
    message.attachments.create!(
      account_id: conversation.account_id,
      file_type: :audio,
      file: {
        io: recording_file,
        filename: recording_filename(recording_file),
        content_type: recording_content_type(recording_file)
      }
    )
  end

  def update_recording_metadata!(message)
    content_attributes = (message.content_attributes || {}).deep_dup
    content_attributes['data'] ||= {}
    content_attributes['data']['meta'] ||= {}
    content_attributes['data']['meta']['recording'] = {
      'sid' => recording_sid,
      'duration' => normalized_recording_duration
    }.compact

    message.update!(content_attributes: content_attributes)
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
    @account_sid ||= channel_config.fetch('account_sid')
  end

  def auth_token
    @auth_token ||= channel_config.fetch('auth_token')
  end

  def channel_config
    @channel_config ||= conversation.inbox.channel.provider_config_hash
  end
end
