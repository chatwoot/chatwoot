class TranscribeAudioMessageJob < ApplicationJob
  queue_as :default

  # Retry configuration for transient errors
  retry_on Openai::Exceptions::RateLimitError, wait: :polynomially_longer, attempts: 3
  retry_on Openai::Exceptions::NetworkError, wait: :polynomially_longer, attempts: 3

  # Discard on permanent failures with error handling
  discard_on Openai::Exceptions::InvalidFileError do |job, error|
    job.handle_transcription_error(error)
  end

  discard_on Openai::Exceptions::AuthenticationError do |job, error|
    job.handle_transcription_error(error)
  end

  # rubocop:disable Metrics/MethodLength
  def perform(message_id, attachment_id)
    @message_id = message_id
    @attachment_id = attachment_id
    @message = Message.find_by(id: message_id)
    @attachment = Attachment.find_by(id: attachment_id)

    if @message.blank?
      Rails.logger.error "Message not found: #{message_id}"
      return
    end

    if @attachment.blank?
      Rails.logger.error "Attachment not found: #{attachment_id}"
      return
    end

    Rails.logger.info "Starting transcription for message #{message_id}, attachment #{attachment_id}"

    result = Openai::AudioTranscriptionService.new(
      attachment: @attachment,
      account: @message.account
    ).process

    return unless result

    store_transcription_metadata(@message, result)
    broadcast_transcription_update(@message)

    Rails.logger.info "Transcription completed for message #{message_id}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Record not found: #{e.message}"
  end
  # rubocop:enable Metrics/MethodLength

  def handle_transcription_error(error)
    Rails.logger.error "Transcription failed for message #{@message_id}: #{error.message}"

    message = Message.find_by(id: @message_id)
    return unless message

    # Store error in metadata
    metadata = message.additional_attributes || {}
    metadata['transcription'] = {
      'error' => error.message,
      'failed_at' => Time.current.iso8601
    }
    message.update!(additional_attributes: metadata)

    # Broadcast update to clear "Transcribing audio..." status
    broadcast_transcription_error(message)
  end

  private

  def store_transcription_metadata(message, result)
    # Update message content with transcription text
    new_content = if message.content.present?
                    "#{message.content}\n\n#{result[:text]}"
                  else
                    result[:text]
                  end

    # Store metadata in additional_attributes
    metadata = message.additional_attributes || {}
    metadata['transcription'] = {
      'language' => result[:language],
      'duration' => result[:duration],
      'transcribed_at' => Time.current.iso8601
    }

    message.update!(content: new_content, additional_attributes: metadata)
  end

  def broadcast_transcription_update(message)
    ActionCable.server.broadcast(
      "messages:#{message.conversation_id}",
      {
        event: 'message.updated',
        data: message.push_event_data
      }
    )
  end

  def broadcast_transcription_error(message)
    ActionCable.server.broadcast(
      "messages:#{message.conversation_id}",
      {
        event: 'message.updated',
        data: message.push_event_data
      }
    )
  end
end
