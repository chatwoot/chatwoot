class Campaigns::RecoverWhatsappCampaignsJob < ApplicationJob
  queue_as :scheduled_jobs

  STALE_AFTER = 15.minutes

  def perform
    Campaign.processing.where(campaign_type: :one_off).where.not(whatsapp_cursor: nil)
            .where(updated_at: ...STALE_AFTER.ago).find_each do |campaign|
      Campaigns::SendWhatsappBatchJob.perform_later(campaign, campaign.whatsapp_cursor)
    end
  end
end
