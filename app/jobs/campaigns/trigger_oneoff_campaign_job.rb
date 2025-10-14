class Campaigns::TriggerOneoffCampaignJob < ApplicationJob
  queue_as :medium

  def perform(campaign)
    campaign.trigger!
  end
end
