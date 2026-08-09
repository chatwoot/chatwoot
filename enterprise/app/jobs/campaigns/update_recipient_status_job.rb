class Campaigns::UpdateRecipientStatusJob < ApplicationJob
  queue_as :low

  def perform(status)
    status = status.with_indifferent_access
    CampaignRecipient.find_by(source_id: status[:id])&.update_from_whatsapp_status!(status)
  end
end
