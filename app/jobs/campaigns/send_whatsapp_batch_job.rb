class Campaigns::SendWhatsappBatchJob < ApplicationJob
  queue_as :low

  def perform(campaign, cursor = 0)
    return if campaign.completed?

    next_cursor = Whatsapp::OneoffCampaignService.new(campaign: campaign).perform_batch(cursor)
    if next_cursor
      self.class.perform_later(campaign, next_cursor)
    else
      campaign.with_lock { campaign.completed! unless campaign.completed? }
    end
  end
end
