class ChatQueue::Queue::FetchService
  pattr_initialize [:account!]

  def fetch_queue_entry(inbox_id)
    group = priority_group_for_inbox(inbox_id)

    entry = ConversationQueue.for_account(account.id)
                             .for_priority_group(group)
                             .waiting
                             .order(:position, :queued_at)
                             .first

    unless entry
      Rails.logger.info("[QUEUE][fetch] No entries for inbox #{inbox_id}")
      return nil
    end

    entry
  end

  def fetch_specific_entry(conv_id)
    entry = ConversationQueue.find_by(conversation_id: conv_id, status: :waiting)

    unless entry
      Rails.logger.info("[QUEUE][fetch_specific][conv=#{conv_id}] No waiting entry found")
      return nil
    end

    entry
  end

  def next_in_queue(inbox_id)
    group = priority_group_for_inbox(inbox_id)

    Rails.logger.info("[QUEUE][next] Fetching next conversation for account #{account.id}")

    ConversationQueue.for_account(account.id)
                     .for_priority_group(group)
                     .waiting
                     .first
                     &.conversation
  end

  def queue_size(inbox_id)
    group = priority_group_for_inbox(inbox_id)

    size = ConversationQueue.for_account(account.id)
                            .for_priority_group(group)
                            .waiting
                            .count

    Rails.logger.info("[QUEUE][size] Queue size=#{size} for account #{account.id}")

    size
  end

  def priority_group_for_inbox(inbox_id)
    @priority_groups ||= {}
    @priority_groups[inbox_id] ||= Inbox.find(inbox_id).priority_group
  end
end
