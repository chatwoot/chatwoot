class ConversationMonitors::RetryJob < ApplicationJob
  queue_as :monitors_backfill

  def perform(monitor_id)
    monitor = ConversationMonitors::Monitor.find_by(id: monitor_id)
    return unless monitor&.collecting?

    version = monitor.collection_version
    recheck_requested_at = monitor.recheck_requested_at

    monitor.evaluations.where(status: %w[pending error]).includes(:conversation).find_each do |evaluation|
      return false unless ConversationMonitors::Scheduler.request_for_monitor(evaluation.conversation, monitor, version)

      ConversationMonitors::Scheduler.wake(evaluation.conversation_id)
    end
    complete_recheck(monitor, version, recheck_requested_at)
    monitor.scans.pending.each { |scan| ConversationMonitors::Scheduler.start_scan(scan.id) }
  end

  private

  def complete_recheck(monitor, version, requested_at)
    monitor.with_lock do
      monitor.update!(recheck_requested_at: nil) if monitor.collection_version == version && monitor.recheck_requested_at == requested_at
    end
  end
end
