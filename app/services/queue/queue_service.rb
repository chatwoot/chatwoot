class Queue::QueueService
  pattr_initialize [:account!]

  def add_to_queue(conversation)
    return false unless account.queue_enabled?
    return false if conversation.assignee.present?
    return false if ConversationQueue.exists?(conversation_id: conversation.id)

    entry = ConversationQueue.create!(
      conversation: conversation,
      account: account,
      queued_at: Time.current,
      status: :waiting
    )

    return false unless entry.persisted?

    conversation.update!(status: :queued) unless conversation.queued?

    send_queue_notification(conversation)

    Queue::ProcessQueueJob.perform_later(account.id)

    true
  end

  def assign_from_queue(agent)
    return nil unless account.queue_enabled?
    return nil unless agent_available?(agent)

    entry = find_next_queue_entry(agent)
    return nil unless entry&.conversation

    if entry.conversation.assignee.present?
      entry.update!(status: :assigned, assigned_at: Time.current)
      return nil
    end

    assign_conversation(entry, agent)
  end

  def remove_from_queue(conversation)
    entry = ConversationQueue.find_by(conversation_id: conversation.id)
    return unless entry&.waiting?

    entry.update!(
      status: :left,
      left_at: Time.current
    )

    wait_time = entry.wait_time_seconds
    QueueStatistic.update_statistics_for(
      account.id,
      wait_time_seconds: wait_time,
      left: true
    )
  end

  def next_in_queue
    ConversationQueueEntry
      .for_account(account.id)
      .waiting
      .first
  end

  def queue_size
    ConversationQueue
      .for_account(account.id)
      .waiting
      .count
  end

  private

  def find_next_queue_entry(agent)
    allowed_inboxes = InboxMember.where(user_id: agent.id).pluck(:inbox_id)

    allowed_teams = Team.where(id: TeamMember.where(user_id: agent.id).select(:team_id)).pluck(:id)

    ConversationQueue
      .joins(:conversation)
      .where(account_id: account.id, status: :waiting)
      .where(
        "conversations.inbox_id IN (:inboxes)
         OR conversations.team_id IN (:teams)",
        inboxes: allowed_inboxes,
        teams: allowed_teams
      )
      .order(:queued_at)
      .first
  end

  def assign_conversation(entry, agent)
    return nil unless agent.present? && agent_available?(agent)

    entry.update!(
      status: :assigned,
      assigned_at: Time.current
    )

    conversation = entry.conversation
    conversation.update!(
      assignee: agent,
      status: :open
    )

    update_statistics(entry)
    send_assigned_notification(conversation)

    conversation
  end

  def update_statistics(entry)
    wait_time = entry.wait_time_seconds
    QueueStatistic.update_statistics_for(
      account.id,
      wait_time_seconds: wait_time,
      assigned: true
    )
  end

  def agent_available?(agent)
    return false if agent.blank?

    account_user = AccountUser.find_by(account_id: account.id, user_id: agent.id)
    return false unless account_user&.online?

    active_count = Conversation
                   .where(assignee_id: agent.id, account_id: account.id)
                   .where.not(status: :resolved)
                   .count

    limit = effective_limit_for_agent(agent.id)
    return true if limit.nil?

    active_count < limit
  end

  def effective_limit_for_agent(agent_id)
    account_user = AccountUser.find_by(account_id: account.id, user_id: agent_id)

    return account_user.active_chat_limit.to_i if account_user&.active_chat_limit_enabled? && account_user.active_chat_limit.present?

    return account.active_chat_limit_value.to_i if account.active_chat_limit_enabled? && account.active_chat_limit_value.present?

    nil
  end

  def send_queue_notification(conversation)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: 'Все операторы сейчас заняты. Мы подключим вас к свободному оператору, как только он освободится.'
    )
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end

  def send_assigned_notification(conversation)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: 'Оператор подключился к диалогу.'
    )
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    true
  end
end
