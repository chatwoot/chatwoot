class Messages::AudioTranscriptionService
  include Integrations::LlmInstrumentation

  WHISPER_MODEL = 'whisper-1'.freeze

  attr_reader :attachment, :message, :account

  def initialize(attachment)
    Llm::Config.initialize!
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

    temp_file_path = fetch_audio_file

    response = instrument_audio_transcription(instrumentation_params(temp_file_path)) do
      RubyLLM.transcribe(temp_file_path, model: WHISPER_MODEL)
    end

    FileUtils.rm_f(temp_file_path)

    transcribed_text = response&.text || response.to_s
    update_transcription(transcribed_text)
    transcribed_text
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

    attachment.update!(meta: { transcribed_text: transcribed_text })
    message.reload.send_update_event
    message.account.increment_response_usage

    return unless ChatwootApp.advanced_search_allowed?

    message.reindex
  end
end
