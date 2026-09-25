class Campaigns::TriggerOneoffCampaignJob < ApplicationJob
  queue_as :within_10_minutes

  def perform(campaign)
    campaign.trigger!
  end
end
