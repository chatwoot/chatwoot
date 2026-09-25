class ConversationMonitors::ScanJob < ApplicationJob
  queue_as :monitors_backfill
  BATCH_SIZE = 100

  def perform(scan_id)
    scan = ConversationMonitors::Scan.find_by(id: scan_id)
    return unless scan&.collecting?

    ids = scan.request_batch(batch_size: BATCH_SIZE)
    ids.each { |id| ConversationMonitors::ProcessJob.set(queue: :monitors_backfill, wait: 3.seconds).perform_later(id) }
    self.class.perform_later(scan_id) unless scan.reload.enumerated_at || scan.cancelled_at
    ConversationMonitors::BroadcastJob.schedule(scan.monitor_id)
  end
end
