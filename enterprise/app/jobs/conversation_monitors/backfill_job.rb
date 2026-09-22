class ConversationMonitors::BackfillJob < ApplicationJob
  queue_as :monitors_backfill
  BATCH_SIZE = 100

  def perform(monitor_id)
    monitor = ConversationMonitors::Monitor.find_by(id: monitor_id)
    return unless monitor&.collecting?
    return if monitor.resumed_at

    backfill = monitor.backfill
    ids = ConversationMonitors::Scan.new(backfill, version: monitor.collection_version, batch_size: BATCH_SIZE).perform
    ids.each { |id| ConversationMonitors::ProcessJob.set(queue: :monitors_backfill, wait: 3.seconds).perform_later(id) }
    self.class.perform_later(monitor_id) unless backfill.reload.enumerated_at
    ConversationMonitors::BroadcastJob.schedule(monitor_id)
  end
end
