class Campaigns::SendWhatsappBatchJob < ApplicationJob
  queue_as :low

  LOCK_TIMEOUT = 15.minutes

  def perform(campaign, cursor = 0)
    key = format(Redis::Alfred::WHATSAPP_CAMPAIGN_MUTEX, campaign_id: campaign.id)
    Redis::LockManager.new.with_lock(key, LOCK_TIMEOUT) do
      send_batch(campaign.reload, cursor)
    end
  end

  private

  def send_batch(campaign, cursor)
    return if campaign.completed?

    next_cursor = Whatsapp::OneoffCampaignService.new(campaign: campaign).perform_batch(cursor)
    if next_cursor
      self.class.perform_later(campaign, next_cursor)
    else
      campaign.with_lock { campaign.completed! unless campaign.completed? }
    end
  end
end
