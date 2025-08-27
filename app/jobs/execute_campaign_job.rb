class ExecuteCampaignJob < ApplicationJob
  queue_as :default

  def perform(campaign)
    # Campaign execution logic here
    Rails.logger.info "Executing campaign: #{campaign.name}"
  end
end
