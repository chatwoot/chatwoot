class Campaigns::SendWhatsappBatchJob < ApplicationJob
  queue_as :low

  def perform(batch)
    campaign = batch.campaign
    return if campaign.completed?

    batch.with_lock do
      unless batch.processed_at?
        Whatsapp::OneoffCampaignService.new(campaign: campaign).perform_batch(batch.contact_ids)
        batch.update!(processed_at: Time.current)
      end
    end

    next_batch = campaign.campaign_batches.where(processed_at: nil).order(:id).first
    if next_batch
      self.class.perform_later(next_batch)
    else
      campaign.with_lock { campaign.completed! unless campaign.completed? }
    end
  end
end
