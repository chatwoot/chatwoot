class Messages::AudioTranscriptionService
  attr_reader :attachment, :message, :account

  def initialize(attachment)
    @attachment = attachment
    @message = attachment.message
    @account = message&.account
  end

  def perform
    skip_reason = transcription_skip_reason
    return { error: skip_reason } if skip_reason

    transcriptions = transcribe_audio
    Rails.logger.info "Audio transcription successful: #{transcriptions}"
    { success: true, transcriptions: transcriptions }
  rescue Faraday::UnauthorizedError
    Rails.logger.warn('Skipping audio transcription: OpenAI configuration is invalid or disabled (401 Unauthorized).')
    { error: 'OpenAI configuration is invalid or disabled (401)' }
  rescue Faraday::BadRequestError => e
    # The API rejected this audio file. Retrying sends the same file, so the caller carries on without a transcript.
    Rails.logger.warn("Skipping audio transcription for attachment #{attachment.id}: " \
                      "rejected with #{e.response&.dig(:status)} #{e.response&.dig(:body)}")
    { error: 'Audio rejected by the transcription API' }
  end

  private

  def transcription_skip_reason
    return 'Message not found' if message.blank?
    return 'Transcription disabled for this inbox' if call_recording_transcription_disabled?
    return 'Transcription limit exceeded' unless Llm::SpeechToTextService.available_for?(account)

    'Audio too large for transcription' if Llm::SpeechToTextService.too_large?(attachment.file&.blob)
  end

  # Call recordings honour the inbox's "Transcribe recordings" setting; ordinary voice notes don't.
  def call_recording_transcription_disabled?
    message.voice_call? && !message.inbox.channel.transcription_enabled?
  end

  def transcribe_audio
    transcribed_text = attachment.meta&.[]('transcribed_text') || ''
    return transcribed_text if transcribed_text.present?

    transcribed_text = Llm::SpeechToTextService.new(blob: attachment.file.blob, account: account).perform
    update_transcription(transcribed_text)
    transcribed_text
  end

  def update_transcription(transcribed_text)
    return if transcribed_text.blank?

    attachment.update!(meta: { transcribed_text: transcribed_text })
    message.reload.send_update_event

    return unless ChatwootApp.advanced_search_allowed?

    message.reindex
  end
end
