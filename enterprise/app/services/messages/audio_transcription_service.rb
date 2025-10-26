class Messages::AudioTranscriptionService < Llm::BaseOpenAiService
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
  rescue StandardError => e
    # Refund credit if transcription failed
    refund_credit
    raise e
  end

  private

  def can_transcribe?
    return false unless account.feature_enabled?('captain_integration')
    return false if account.audio_transcriptions.blank?

    account.usage_limits[:captain][:responses][:current_available].positive?
  end

  def refund_credit
    credit_service = Enterprise::Ai::CaptainCreditService.new(account: account)
    credit_service.check_and_use_credits(
      feature: 'ai_audio_transcription',
      amount: -1, # Negative to refund
      metadata: {
        'message_id' => message.id,
        'attachment_id' => attachment.id,
        'conversation_id' => message.conversation_id,
        'refund' => true
      }
    )
  end

  def fetch_audio_file
    temp_dir = Rails.root.join('tmp/uploads')
    FileUtils.mkdir_p(temp_dir)
    temp_file_path = File.join(temp_dir, attachment.file.filename.to_s)
    File.write(temp_file_path, attachment.file.download, mode: 'wb')
    temp_file_path
  end

  def transcribe_audio
    transcribed_text = attachment.meta&.[]('transcribed_text') || ''
    return transcribed_text if transcribed_text.present?

    temp_file_path = fetch_audio_file

    response = @client.audio.transcribe(
      parameters: {
        model: 'whisper-1',
        file: File.open(temp_file_path),
        temperature: 0.4
      }
    )

    FileUtils.rm_f(temp_file_path)

    update_transcription(response['text'])
    response['text']
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
