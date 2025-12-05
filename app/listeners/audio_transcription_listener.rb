class AudioTranscriptionListener < BaseListener
  def message_created(event)
    message = event.data[:message]

    return unless audio_attachments?(message)
    return unless api_key_available?(message.account)

    Rails.logger.debug { "AudioTranscriptionListener: Processing message #{message.id} with audio attachments" }

    message.attachments.where(file_type: :audio).find_each do |attachment|
      Rails.logger.info "Enqueuing transcription job for message #{message.id}, attachment #{attachment.id}"
      # Delay slightly to allow ActiveStorage to write file to disk (avoids race condition)
      TranscribeAudioMessageJob.set(wait: 2.seconds).perform_later(message.id, attachment.id)
    end
  end

  private

  def audio_attachments?(message)
    message.attachments.any? { |attachment| attachment.file_type == 'audio' }
  end

  def api_key_available?(account)
    # Check if OpenAI integration has audio_transcription enabled
    openai_hook = account.hooks.find_by(app_id: 'openai', status: 'enabled')

    if openai_hook.blank?
      Rails.logger.debug do
        "AudioTranscriptionListener: Skipping transcription for account #{account.id} - " \
          'No enabled OpenAI integration found'
      end
      return false
    end

    # Check if audio_transcription setting is enabled in the integration
    unless openai_hook.settings['audio_transcription'] == true
      Rails.logger.debug do
        "AudioTranscriptionListener: Skipping transcription for account #{account.id} - " \
          'audio_transcription setting is disabled in OpenAI integration'
      end
      return false
    end

    # Verify API key is present
    if openai_hook.settings['api_key'].blank?
      Rails.logger.debug do
        "AudioTranscriptionListener: Skipping transcription for account #{account.id} - " \
          'No API key configured in OpenAI integration'
      end
      return false
    end

    true
  rescue StandardError => e
    Rails.logger.error "AudioTranscriptionListener: Error checking transcription settings for account #{account.id}: #{e.message}"
    false
  end
end
