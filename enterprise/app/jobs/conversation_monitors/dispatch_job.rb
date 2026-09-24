class ConversationMonitors::DispatchJob < ApplicationJob
  queue_as :scheduled_jobs
  PER_ACCOUNT_BATCH = 25

  def perform
    Account.feature_conversation_monitors.find_each do |account|
      next unless ConversationMonitors::Configuration.enabled?(account) && account.conversation_monitors.active.exists?

      dispatch_account(account)
    end
    ConversationMonitors::Monitor.where.not(deleted_at: nil).limit(100).destroy_all
  end

  private

  def dispatch_account(account)
    account.conversation_monitors.active.where.not(recheck_requested_at: nil).find_each do |monitor|
      ConversationMonitors::RetryJob.perform_later(monitor.id, monitor.recheck_requested_at)
    end
    dispatch_scans(account)
    ConversationMonitors::WorkItem.due.where(account_id: account.id).order(:due_at).limit(PER_ACCOUNT_BATCH).pluck(:conversation_id).each do |id|
      ConversationMonitors::ProcessJob.perform_later(id)
    end
  end

  def dispatch_scans(account)
    ConversationMonitors::Scan.pending.joins(:monitor).merge(account.conversation_monitors.active)
                              .where('conversation_monitor_scans.collection_version = conversation_monitors.collection_version')
                              .find_each { |scan| ConversationMonitors::ScanJob.perform_later(scan.id) }
  end
end
