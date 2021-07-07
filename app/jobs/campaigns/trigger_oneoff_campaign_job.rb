class Campaigns::TriggerOneoffCampaignJob < ApplicationJob
  queue_as :high

  def perform(campaign)
    # TODO
    # iterate through audience
    # fetch source ids for each audience
    # trigger a twilio message call
  end
end
