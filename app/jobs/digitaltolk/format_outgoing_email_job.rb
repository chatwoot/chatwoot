class Digitaltolk::FormatOutgoingEmailJob < ApplicationJob
  queue_as :low

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    Digitaltolk::FormatOutgoingEmailService.new(message).perform
  rescue StandardError => e
    Rails.logger.error "Error formatting outgoing email for message #{message_id}: #{e.message}"
  end
end
