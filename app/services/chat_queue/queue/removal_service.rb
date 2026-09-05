class ChatQueue::Queue::RemovalService
  pattr_initialize [:account!, :conversation!, :reason]

  def remove!
    cid = conversation.id
    Rails.logger.info("[QUEUE][remove][conv=#{cid}] Removing from queue, reason: #{reason}")

    entry = ConversationQueue.find_by(conversation_id: cid, status: :waiting)

    unless entry
      Rails.logger.info("[QUEUE][remove][conv=#{cid}] Skip: no waiting entry")
      return nil
    end

    left_queue = reason == :resolved

    entry.update!(
      status: left_queue ? :left : :assigned,
      left_at: left_queue ? Time.current : nil,
      assigned_at: left_queue ? nil : Time.current
    )

    update_statistics(entry, left: left_queue)

    entry
  rescue StandardError => e
    Rails.logger.error("[QUEUE][remove][conv=#{cid}] Exception: #{e.class} #{e.message}")
    nil
  end

  private

  def update_statistics(entry, left: false)
    cid = entry.conversation_id
    Rails.logger.info("[QUEUE][remove][conv=#{cid}] Updating statistics (left=#{left})")

    wait_time = entry.wait_time_seconds

    QueueStatistic.update_statistics_for(
      account.id,
      wait_time_seconds: wait_time,
      left: left,
      assigned: !left
    )
  end
end
