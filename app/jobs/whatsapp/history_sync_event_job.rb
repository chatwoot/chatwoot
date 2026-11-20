class Whatsapp::HistorySyncEventJob < MutexApplicationJob
  queue_as :low

  retry_on LockAcquisitionError, wait: 5.seconds, attempts: 120
  retry_on Whatsapp::HistorySync::Importer::MissingHistoricalMessageError, wait: 10.seconds, attempts: 12 do |job, error|
    event = WhatsappHistorySyncEvent.find_by(id: job.arguments.first)
    event&.update!(status: :failed, error_message: error.message)
    event&.history_sync&.update!(status: :failed, last_error_message: error.message)
  end

  def perform(event_id)
    event = WhatsappHistorySyncEvent.find(event_id)
    return if event.processed?

    with_lock("whatsapp_history_sync:#{event.whatsapp_history_sync_id}", 10.minutes) do
      process_event(event.reload)
    end
  end

  private

  def process_event(event)
    return if event.processed?

    event.update!(status: :processing, error_message: nil)
    sync = event.history_sync
    sync.update!(status: :processing) unless sync.not_shared? || sync.completed?

    result = Whatsapp::HistorySync::Importer.new(event).perform
    event.update!(status: :processed, processed_at: Time.current)
    update_sync(sync, result)
  rescue Whatsapp::HistorySync::Importer::MissingHistoricalMessageError
    event.update!(status: :pending)
    raise
  rescue StandardError => e
    event.update!(status: :failed, error_message: e.message)
    event.history_sync.update!(status: :failed, last_error_message: e.message)
    Rails.logger.error("[WHATSAPP HISTORY SYNC] Event #{event.id} failed: #{e.class} - #{e.message}")
  end

  def update_sync(sync, result)
    sync.reload
    attributes = sync_counter_attributes(sync, result)
    attributes.merge!(sync_status_attributes(sync, result, attributes[:progress]))
    sync.update!(attributes)
  end

  def sync_counter_attributes(sync, result)
    {
      progress: [sync.progress, result.progress.to_i].max,
      imported_messages: sync.imported_messages + result.messages,
      imported_conversations: sync.imported_conversations + result.conversations
    }
  end

  def sync_status_attributes(sync, result, progress)
    return { status: result.terminal_status, completed_at: Time.current } if result.terminal_status
    return { status: :completed, completed_at: Time.current } if sync_complete?(sync, progress)

    { status: :processing }
  end

  def sync_complete?(sync, progress)
    progress == 100 && sync.events.where.not(status: :processed).none?
  end
end
