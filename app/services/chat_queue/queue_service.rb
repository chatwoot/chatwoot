class ChatQueue::QueueService
  pattr_initialize [:account!]

  def add_to_queue(conversation)
    return false unless account.queue_enabled?
    return false if in_queue?(conversation.id)
  
    conversation.update!(assignee_id: nil) if conversation.assignee_id.present?

    entry = ConversationQueue.create!(
      conversation: conversation,
      account: account,
      queued_at: Time.current,
      status: :waiting
    )

    conversation.update!(status: :queued) unless conversation.queued?

    send_queue_notification(conversation)

    Queue::ProcessQueueJob.perform_later(account.id)
    true
  end

  def online_agents_list
    (OnlineStatusTracker.get_available_users(account.id) || {})
      .select { |_id, status| status == "online" }
      .keys
      .map(&:to_i)
  end
  
  def assign_from_queue(agent)
    return nil unless account.queue_enabled?
    return nil unless agent_available?(agent)

    entry = find_next_queue_entry(agent)
    return nil unless entry

    assign_entry(entry, agent)
  end

  def remove_from_queue(conversation)
    entry = ConversationQueue.find_by(conversation_id: conversation.id)
    return unless entry&.waiting?

    entry.update!(status: :left, left_at: Time.current)

    wait_time = entry.wait_time_seconds
    QueueStatistic.update_statistics_for(
      account.id,
      wait_time_seconds: wait_time,
      left: true
    )
  end

  def next_in_queue
    ConversationQueue.for_account(account.id).waiting.first&.conversation
  end

  def queue_size
    ConversationQueue.for_account(account.id).waiting.count
  end

  def assign_specific_from_queue!(agent, conv_id)
    return nil unless account.queue_enabled?
    return nil unless agent_available?(agent)

    entry = ConversationQueue.find_by(conversation_id: conv_id, status: :waiting)
    return nil unless entry

    conversation = entry.conversation
    return nil unless conversation&.queued?
    return nil if conversation.assignee_id.present?
    return nil unless conversation_allowed_for_agent?(conversation, agent)

    assign_entry(entry, agent)
  end

  def agent_available?(agent)
    return false if agent.blank?

    statuses = OnlineStatusTracker.get_available_users(account.id) || {}
    return false unless statuses[agent.id.to_s] == "online"

    active_count = Conversation
      .where(account_id: account.id, assignee_id: agent.id)
      .where.not(status: :resolved)
      .count

    limit = effective_limit_for_agent(agent.id)
    limit.nil? || active_count < limit
  end

  def conversation_allowed_for_agent?(conversation, agent)
    InboxMember.exists?(inbox_id: conversation.inbox_id, user_id: agent.id)
  end
  
  def in_queue?(conversation_id)
    ConversationQueue.exists?(conversation_id: conversation_id, status: :waiting)
  end

  private

  def effective_limit_for_agent(agent_id)
    account_user = AccountUser.find_by(account_id: account.id, user_id: agent_id)

    if account_user&.active_chat_limit_enabled? && account_user.active_chat_limit.present?
      return account_user.active_chat_limit.to_i
    end

    if account.active_chat_limit_enabled? && account.active_chat_limit_value.present?
      return account.active_chat_limit_value.to_i
    end

    nil
  end

  def assign_entry(entry, agent)
    ConversationQueue.transaction do
      locked_entry = ConversationQueue.lock.find(entry.id)
      conversation = locked_entry.conversation

      return conversation if locked_entry.status == "assigned"
      return conversation if conversation.assignee_id.present?

      unless agent_limit_available?(agent)
        raise ActiveRecord::Rollback
      end

      locked_entry.update!(
        status: :assigned,
        assigned_at: Time.current
      )

      conversation.update!(
        assignee: agent,
        status: :open,
        updated_at: Time.current
      )

      update_statistics(locked_entry)
  
      send_assigned_notification(conversation)
  
      conversation
    end
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
    nil
  end

  def agent_limit_available?(agent)
    limit = effective_limit_for_agent(agent.id)
    return true if limit.nil?

    active_chats = Conversation
      .where(account_id: account.id, assignee_id: agent.id)
      .where.not(status: :resolved)
      .lock("FOR UPDATE")
      .pluck(:id)

    active_chats.size < limit
  end  

  def find_next_queue_entry(agent)
    allowed_inboxes = InboxMember.where(user_id: agent.id).pluck(:inbox_id)

    ConversationQueue
      .joins(:conversation)
      .where(account_id: account.id, status: :waiting)
      .where(
        "conversations.inbox_id IN (:inboxes)",
        inboxes: allowed_inboxes
      )
      .order(:position, :queued_at)
      .first
  end

  def send_queue_notification(conversation)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: 'Все операторы сейчас заняты. Мы подключим вас к свободному оператору, как только он освободится.'
    )
  rescue => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
  end

  def send_assigned_notification(conversation)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: 'Оператор подключился к диалогу.'
    )
  rescue => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
  end

  def update_statistics(entry)
    wait_time = entry.wait_time_seconds

    QueueStatistic.update_statistics_for(
      account.id,
      wait_time_seconds: wait_time,
      assigned: true
    )
  end
end
