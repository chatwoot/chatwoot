class RetryWhatsappTemplateMessagesJob < ApplicationJob
  queue_as :low

  def perform
    # Find messages that:
    # * have status :error
    # * were updated in the last 2 hours
    # * contain template_params (i.e., are template messages)
    Message
      .where(status: :error)
      .where('updated_at >= ?', 2.hours.ago)
      .where("additional_attributes ->> 'template_params' IS NOT NULL")
      .find_each do |message|
        retry_message(message)
      end
  end

  private

  def retry_message(message)
    # Re‑use the same service that originally sent the message
    service = Whatsapp::SendOnWhatsappService.new(message: message)

    begin
      service.perform_reply
      # If the send succeeds, mark the message as sent
      message.update!(status: :sent)
    rescue StandardError => e
      # Log the failure; the job will be retried automatically by Sidekiq
      Rails.logger.warn "Retry failed for Message #{message.id}: #{e.message}"
      # Re‑raise to trigger Sidekiq retry
      raise
    end
  end
end

