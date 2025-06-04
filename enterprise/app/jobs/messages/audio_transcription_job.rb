class Messages::AudioTranscriptionJob < ApplicationJob
  queue_as :low

  def perform(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return if attachment.blank?

    message = attachment.message
    return if message.conversation.pending?

    if message.account.captain_assistants.empty?
      Rails.logger.info "No captain assistants found for the account #{message.account_id}"
      return
    end

    Messages::AudioTranscriptionService.new(attachment).perform
  rescue StandardError => e
    Rails.logger.error "Error in AudioTranscriptionJob: #{e.message}"
    ChatwootExceptionTracker.new(e).capture_exception
  end
end
