class CampaignExecuteJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by(id: campaign_id)
    return unless campaign && (campaign.scheduled? || campaign.sending?)

    # idempotency guard: avoid double send
    return if campaign.sent? || campaign.canceled?

    campaign.update!(status: :sending)

    # TODO: hand off to your n8n service (stubbed here)
    # N8nService.trigger_campaign!(campaign)  # implement later

    campaign.update!(status: :sent)
  rescue => e
    Rails.logger.error("[CampaignExecuteJob] #{campaign_id}: #{e.class} #{e.message}")
    campaign&.update!(status: :failed)
    raise
  end
end
