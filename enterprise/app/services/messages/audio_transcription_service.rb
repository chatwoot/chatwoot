class Messages::AudioTranscriptionService< Llm::LegacyBaseOpenAiService
  include Integrations::LlmInstrumentation

  WHISPER_MODEL = 'whisper-1'.freeze
  MAX_TRANSCRIPTION_FILE_SIZE = 25.megabytes
  SUPPORTED_AUDIO_EXTENSIONS = %w[flac mp3 mp4 m4a mpeg mpga oga ogg wav webm].freeze

  attr_reader :attachment, :message, :account

  def initialize(attachment)
    super()
    @attachment = attachment
    @message = attachment.message
    @account = message.account
  end

  def perform
    return { error: 'Transcription limit exceeded' } unless can_transcribe?
    return { error: 'Message not found' } if message.blank?

    transcriptions = transcribe_audio
    Rails.logger.info "Audio transcription successful: #{transcriptions}"
    { success: true, transcriptions: transcriptions }
  end

  private

  def can_transcribe?
    return false unless account.feature_enabled?('captain_integration')
    return false if account.audio_transcriptions.blank?

    account.usage_limits[:captain][:responses][:current_available].positive?
  end

  def fetch_audio_file
    temp_dir = Rails.root.join('tmp/uploads/audio-transcriptions')
    FileUtils.mkdir_p(temp_dir)
    temp_file_path = File.join(temp_dir, "#{attachment.file.blob.key}-#{attachment.file.filename}")

    File.open(temp_file_path, 'wb') do |file|
      attachment.file.blob.open do |blob_file|
        IO.copy_stream(blob_file, file)
      end
    end

    temp_file_path
  end

  def transcribe_audio
    transcribed_text = attachment.meta&.[]('transcribed_text') || ''
    return transcribed_text if transcribed_text.present?

    return '' unless transcription_input_valid?

    temp_file_path = fetch_audio_file
    transcribed_text = transcribe_with_openai(temp_file_path)
    return '' if transcribed_text.blank?

    update_transcription(transcribed_text)
    transcribed_text
  ensure
    FileUtils.rm_f(temp_file_path) if temp_file_path.present?
  end

  def instrumentation_params(file_path)
    {
      span_name: 'llm.messages.audio_transcription',
      model: WHISPER_MODEL,
      account_id: account&.id,
      feature_name: 'audio_transcription',
      file_path: file_path
    }
  end

  def update_transcription(transcribed_text)
    return if transcribed_text.blank?

    attachment.update!(meta: attachment_meta.merge('transcribed_text' => transcribed_text).except('transcription_error'))
    message.reload.send_update_event
    message.account.increment_response_usage

    return unless ChatwootApp.advanced_search_allowed?

    message.reindex
  end

  def transcribe_with_openai(temp_file_path)
    File.open(temp_file_path, 'rb') do |file|
      response = @client.audio.transcribe(
        parameters: {
          model: WHISPER_MODEL,
          file: file,
          temperature: 0.4
        }
      )

      response['text']
    end
  rescue Faraday::BadRequestError => e
    handle_transcription_bad_request(e)
    nil
  end

  def transcription_input_valid?
    return unsupported_input('missing_file') if audio_blob.blank?
    return unsupported_input('unsupported_format') unless supported_audio_format?
    return unsupported_input('file_too_large') unless supported_audio_size?

    true
  end

  def supported_audio_format?
    extension = audio_blob.filename.extension_without_delimiter.to_s.downcase
    SUPPORTED_AUDIO_EXTENSIONS.include?(extension)
  end

  def supported_audio_size?
    audio_blob.byte_size <= MAX_TRANSCRIPTION_FILE_SIZE
  end

  def unsupported_input(error_code)
    persist_transcription_error(error_code)
    Rails.logger.info("Audio transcription skipped for unsupported input: #{transcription_log_context(error_code: error_code)}")
    false
  end

  def handle_transcription_bad_request(error)
    status_code = error.response&.dig(:status)
    response_body = error.response&.dig(:body).to_s
    persist_transcription_error('upstream_bad_request')
    log_context = transcription_log_context(
      error_code: 'upstream_bad_request',
      status_code: status_code,
      response_body: response_body.truncate(500),
      error_message: error.message
    )

    Rails.logger.warn("Audio transcription request failed with bad request: #{log_context}")
  end

  def persist_transcription_error(error_code)
    attachment.update(meta: attachment_meta.merge('transcription_error' => error_code))
  end

  def attachment_meta
    attachment.meta.is_a?(Hash) ? attachment.meta : {}
  end

  def audio_blob
    attachment.file&.blob
  end

  def transcription_log_context(extra = {})
    {
      attachment_id: attachment.id,
      message_id: message&.id,
      account_id: account&.id,
      filename: audio_blob&.filename&.to_s,
      content_type: audio_blob&.content_type,
      byte_size: audio_blob&.byte_size,
      endpoint: uri_base
    }.merge(extra)
  end
end
