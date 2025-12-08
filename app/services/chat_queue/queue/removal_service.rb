class ChatQueue::Queue::RemovalService
  pattr_initialize [:account!, :conversation!]

  def remove!
    cid = conversation.id
    Rails.logger.info("[QUEUE][remove][conv=#{cid}] Removing from queue")

    entry = ConversationQueue.find_by(conversation_id: cid, status: :waiting)

    unless entry
      Rails.logger.info("[QUEUE][remove][conv=#{cid}] Skip: no waiting entry")
      return nil
    end

    entry.update!(
      status: :left,
      left_at: Time.current
    )

    update_statistics(entry)

    entry
  rescue StandardError => e
    Rails.logger.error("[QUEUE][remove][conv=#{cid}] Exception: #{e.class} #{e.message}")
    nil
  end

  private

  def update_statistics(entry)
    cid = entry.conversation_id
    Rails.logger.info("[QUEUE][remove][conv=#{cid}] Updating statistics")

    wait_time = entry.wait_time_seconds

    QueueStatistic.update_statistics_for(
      account.id,
      wait_time_seconds: wait_time,
      left: true
    )
  end
end
