class Voice::Provider::Twilio::RecordingAttachmentService
  DEFAULT_FILENAME_EXTENSION = 'wav'.freeze
  ALLOWED_CONTENT_TYPE_PREFIXES = %w[audio/].freeze

  pattr_initialize [:call!, :recording_sid!, :recording_url!, { recording_duration: nil }]

  def perform
    return if recording_sid.blank? || recording_url.blank?
    return if already_attached?

    SafeFetch.fetch(
      recording_url,
      http_basic_authentication: [account_sid, auth_token],
      allowed_content_type_prefixes: ALLOWED_CONTENT_TYPE_PREFIXES
    ) do |result|
      persist_recording!(result)
    end

    # Bump the message updated_at so the message.updated dispatcher rebroadcasts
    # the embedded Call payload (now with recording_url) to connected clients.
    call.message&.touch # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def persist_recording!(result)
    call.with_lock do
      next if already_attached?

      attach_recording!(result)
      call.recording_sid = recording_sid
      call.duration_seconds ||= normalized_recording_duration
      call.save!
    end
  end

  def already_attached?
    call.recording.attached? && call.recording_sid.to_s == recording_sid.to_s
  end

  def attach_recording!(result)
    call.recording.attach(
      io: result.tempfile,
      filename: recording_filename(result),
      content_type: recording_content_type(result)
    )
  end

  def normalized_recording_duration
    return if recording_duration.blank?

    recording_duration.to_i
  end

  def recording_filename(result)
    return result.original_filename if result.original_filename.present?

    "call-recording-#{recording_sid}.#{recording_extension(result)}"
  end

  def recording_extension(result)
    content_type = recording_content_type(result)
    Rack::Mime::MIME_TYPES.invert[content_type].to_s.delete_prefix('.').presence || DEFAULT_FILENAME_EXTENSION
  end

  def recording_content_type(result)
    result.content_type.presence || 'audio/wav'
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
