class Campaigns::UpdateRecipientStatusJob < ApplicationJob
  class RecipientNotFoundError < StandardError; end

  queue_as :low
  retry_on RecipientNotFoundError, wait: ->(executions) { executions * 2.seconds }, attempts: 5 do |job, _error|
    Rails.logger.warn "Campaign recipient status could not be reconciled for inbox #{job.arguments.first}"
  end

  def perform(inbox_id, status)
    status = status.with_indifferent_access
    inbox = Inbox.find(inbox_id)
    recipient = CampaignRecipient.find_by(account_id: inbox.account_id, inbox_id: inbox.id, source_id: status[:id])
    raise RecipientNotFoundError unless recipient

    recipient.update_from_whatsapp_status!(status)
  end
end
