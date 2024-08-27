class Campaigns::TriggerFlexibleCampaignsJob < ApplicationJob
  queue_as :scheduled_jobs
  retry_on StandardError, attempts: 0

  def perform
    Campaign.where(campaign_type: :flexible, enabled: true,
                   campaign_status: :active).all.find_each(batch_size: 100, &:trigger!)
  end
end
