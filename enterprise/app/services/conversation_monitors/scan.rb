class ConversationMonitors::Scan
  def initialize(scan, version:, batch_size:)
    @scan = scan
    @version = version
    @batch_size = batch_size
  end

  def perform
    @scan.with_lock do
      return [] if @scan.enumerated_at || @scan.cancelled_at

      conversations = @scan.population.where('conversations.id > ?', @scan.cursor).order(:id).limit(@batch_size).to_a
      lock_work_items(conversations)
      processed = conversations.take_while do |conversation|
        ConversationMonitors::Scheduler.request_for_monitor(conversation, @scan.monitor, @version)
      end
      advance(processed, complete: processed.size == conversations.size && conversations.size < @batch_size)
      processed.map(&:id)
    end
  end

  private

  def lock_work_items(conversations)
    # The cursor transaction retains locks for the whole batch. Lock every work item
    # before any monitor, matching live evaluation and avoiding a lock-order inversion.
    conversations.each { |conversation| ConversationMonitors::WorkItem.for_conversation(conversation) }
    ConversationMonitors::WorkItem.where(conversation_id: conversations.map(&:id)).order(:id).lock.load
  end

  def advance(processed, complete:)
    @scan.update!(cursor: processed.last&.id || @scan.cursor, enumerated_at: complete ? Time.current : nil)
  end
end
