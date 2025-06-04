class Messages::AudioTranscriptionJob < ApplicationJob
  queue_as :low

  def perform(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return if attachment.blank?

    Messages::AudioTranscriptionService.new(attachment).perform
  rescue StandardError => e
    Rails.logger.error "Error in AudioTranscriptionJob: #{e.message}"
    ChatwootExceptionTracker.new(e).capture_exception
  end
end
