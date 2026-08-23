class TriggerScheduledItemsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # trigger the scheduled campaign jobs
    Campaign.where(campaign_type: :one_off,
                   campaign_status: :active).where(scheduled_at: 3.days.ago..Time.current).all.find_each(batch_size: 100) do |campaign|
      Campaigns::TriggerOneoffCampaignJob.perform_later(campaign)
    end

    # Job to reopen snoozed conversations
    Conversations::ReopenSnoozedConversationsJob.perform_later

    # Job to reopen snoozed notifications
    Notification::ReopenSnoozedNotificationsJob.perform_later

    # Job to auto-resolve conversations
    Account::ConversationsResolutionSchedulerJob.perform_later

    # Resolve or hand off Captain-pending conversations that have gone idle
    schedule_captain_pending_conversation_resolutions

    # Job to sync whatsapp templates
    Channels::Whatsapp::TemplatesSyncSchedulerJob.perform_later

    # Job to trigger pending executions
    AutomationRules::TriggerPendingExecutionsJob.perform_later

    # Job to evaluate applied SLAs
    Sla::TriggerSlasForAccountsJob.perform_later
  end

  private

  # Captain-pending conversations (the AI is holding them) would otherwise stay
  # pending forever once the customer goes quiet. Each inbox's own assistant
  # decides whether to auto-resolve, auto-hand off, or skip based on its config.
  def schedule_captain_pending_conversation_resolutions
    CaptainInbox.includes(:captain_assistant).find_each do |captain_inbox|
      # Orphaned rows (assistant or inbox deleted without a DB-level FK) resolve to
      # nil here; skip them instead of crashing the resolution job on a nil inbox.
      next if captain_inbox.captain_assistant.blank?
      next if captain_inbox.inbox.blank?
      next if captain_inbox.captain_assistant.inactive_conversation_resolution_disabled?

      Captain::InboxPendingConversationsResolutionJob.perform_later(captain_inbox.inbox)
    end
  end
end

TriggerScheduledItemsJob.prepend_mod_with('TriggerScheduledItemsJob')
