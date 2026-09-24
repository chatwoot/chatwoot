class ConversationMonitors::RetryJob < ApplicationJob
  queue_as :monitors_backfill
  # Keep recheck locks outside the ID range used by import-item advisory locks.
  LOCK_BASE = 1_596_600_000_000

  def perform(monitor_id, requested_at = nil)
    ApplicationRecord.connection_pool.with_connection do |connection|
      lock_id = LOCK_BASE + monitor_id
      next unless connection.select_value("SELECT pg_try_advisory_lock(#{lock_id})")

      begin
        retry_monitor(monitor_id, requested_at)
      ensure
        connection.execute("SELECT pg_advisory_unlock(#{lock_id})")
      end
    end
  end

  private

  def retry_monitor(monitor_id, requested_at)
    monitor = ConversationMonitors::Monitor.find_by(id: monitor_id)
    return unless monitor&.collecting?
    return if requested_at && monitor.recheck_requested_at != requested_at

    version = monitor.collection_version
    recheck_requested_at = monitor.recheck_requested_at

    monitor.evaluations.where(status: %w[pending error]).includes(:conversation).find_each do |evaluation|
      return false unless ConversationMonitors::Scheduler.request_for_monitor(evaluation.conversation, monitor, version)

      ConversationMonitors::Scheduler.wake(evaluation.conversation_id)
    end
    complete_recheck(monitor, version, recheck_requested_at)
    monitor.scans.pending.each { |scan| ConversationMonitors::Scheduler.start_scan(scan.id) }
  end

  def complete_recheck(monitor, version, requested_at)
    monitor.with_lock do
      monitor.update!(recheck_requested_at: nil) if monitor.collection_version == version && monitor.recheck_requested_at == requested_at
    end
  end
end
