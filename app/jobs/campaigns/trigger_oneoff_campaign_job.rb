class Campaigns::TriggerOneoffCampaignJob < ApplicationJob
  queue_as :medium
  sidekiq_options retry: 3

  def perform(campaign)
    campaign.trigger!
  end
end
