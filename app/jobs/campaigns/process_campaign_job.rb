# app/jobs/campaigns/process_campaign_job.rb
class Campaigns::ProcessCampaignJob < ApplicationJob
  queue_as :low
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  sidekiq_options(
    unique: :until_executed,
    lock_timeout: 2.hours
  )

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    return unless should_process?(campaign)
    return unless whatsapp_campaign?(campaign)

    begin
      process_whatsapp_campaign(campaign)
    rescue StandardError => e
      handle_campaign_failure(campaign, e)
      raise # Re-raise to trigger retry mechanism
    end
  end

  private

  def should_process?(campaign)
    return false if campaign.completed?
    return false if campaign.scheduled_at && campaign.scheduled_at > Time.current

    return false if campaign.trigger_only_during_business_hours && !during_business_hours?(campaign.account.timezone)

    true
  end

  def whatsapp_campaign?(campaign)
    return true if campaign.inbox.inbox_type == 'Whatsapp'

    campaign.update(campaign_status: :failed)
    false
  end

  def process_whatsapp_campaign(campaign)
    campaign.trigger!
  end

  def handle_campaign_failure(campaign, error)
    campaign.update(campaign_status: :failed)
    ErrorTracker.report(
      error,
      campaign_id: campaign.id,
      account_id: campaign.account_id,
      extra: {
        inbox_type: campaign.inbox.inbox_type,
        template_id: campaign.template_id,
        contacts_count: campaign.contacts.count
      }
    )
    CampaignMailer.failure_notification(
      campaign: campaign,
      error: error
    ).deliver_later
  end

  def during_business_hours?(timezone)
    time = Time.current.in_time_zone(timezone)
    return false unless time.on_weekday?
    return false if time.hour < 9 || time.hour >= 17

    true
  end
end
