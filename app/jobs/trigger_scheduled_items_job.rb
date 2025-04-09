class TriggerScheduledItemsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Rails.logger.info('Say hello to trigger')
    # trigger the scheduled campaign jobs
    Campaign.where(campaign_type: :one_off,
                   campaign_status: :active).where(scheduled_at: 3.days.ago..Time.current).all.find_each(batch_size: 100) do |campaign|
      Campaigns::TriggerOneoffCampaignJob.perform_later(campaign)
    end
    Campaign.where(campaign_type: :whatsapp,
                   campaign_status: :scheduled).all.find_each(batch_size: 100) do |campaign|
      Campaigns::ProcessCampaignJob.perform_later(campaign.id)
    end
    # TODO: filter by scheduled_at time as well
    Campaign.where(campaign_type: :email,
                   campaign_status: :active).where(scheduled_at: 3.days.ago..Time.current).all.find_each(batch_size: 100) do |campaign|
      Campaigns::TriggerOneoffCampaignJob.perform_later(campaign)
    end

    # Job to reopen snoozed conversations
    Conversations::ReopenSnoozedConversationsJob.perform_later

    # Job to reopen snoozed notifications
    Notification::ReopenSnoozedNotificationsJob.perform_later

    # Job to auto-resolve conversations
    Account::ConversationsResolutionSchedulerJob.perform_later

    # Job to sync whatsapp templates
    Channels::Whatsapp::TemplatesSyncSchedulerJob.perform_later

    # Job to clear notifications which are older than 1 month
    Notification::RemoveOldNotificationJob.perform_later
  end
end
