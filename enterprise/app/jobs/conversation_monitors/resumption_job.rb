class ConversationMonitors::ResumptionJob < ApplicationJob
  queue_as :monitors_backfill
  BATCH_SIZE = 100

  def perform(resumption_id)
    resumption = ConversationMonitors::Resumption.find_by(id: resumption_id)
    return unless resumption&.collecting?

    ids = ConversationMonitors::Scan.new(resumption, version: resumption.collection_version, batch_size: BATCH_SIZE).perform
    ids.each { |id| ConversationMonitors::ProcessJob.set(queue: :monitors_backfill, wait: 3.seconds).perform_later(id) }
    self.class.perform_later(resumption_id) unless resumption.reload.enumerated_at || resumption.cancelled_at
    ConversationMonitors::BroadcastJob.schedule(resumption.monitor_id)
  end
end
