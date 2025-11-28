class ChatQueue::QueueService
  pattr_initialize [:account!]

  def add_to_queue(conversation)
    cid = conversation.id
    Rails.logger.info("[QUEUE][add][conv=#{cid}] Start add_to_queue")

    unless account.queue_enabled?
      Rails.logger.info("[QUEUE][add][conv=#{cid}] Skip: queue disabled for account #{account.id}")
      return false
    end

    if in_queue?(cid)
      Rails.logger.info("[QUEUE][add][conv=#{cid}] Skip: already in queue")
      return false
    end

    if conversation.assignee_id.present?
      Rails.logger.info("[QUEUE][add][conv=#{cid}] Clearing assignee #{conversation.assignee_id}")
      conversation.update!(assignee_id: nil)
    end

    Rails.logger.info("[QUEUE][add][conv=#{cid}] Creating queue entry")
    entry = ConversationQueue.create!(
      conversation: conversation,
      account: account,
      inbox_id: conversation.inbox_id,
      queued_at: Time.current,
      status: :waiting
    )

    unless conversation.queued?
      Rails.logger.info("[QUEUE][add][conv=#{cid}] Updating conversation status to queued")
      conversation.update!(status: :queued)
    end

    Rails.logger.info("[QUEUE][add][conv=#{cid}] Sending queue notification")
    send_queue_notification(conversation)

    Rails.logger.info("[QUEUE][add][conv=#{cid}] Enqueue ProcessQueueJob")
    Queue::ProcessQueueJob.perform_later(account.id, conversation.inbox_id)

    Rails.logger.info("[QUEUE][add][conv=#{cid}] Completed successfully")
    true
  end

  def online_agents_list
    Rails.logger.info("[QUEUE][online] Fetching online agents for account #{account.id}")

    agent_ids = (OnlineStatusTracker.get_available_users(account.id) || {})
                 .select { |_id, status| status == "online" }
                 .keys
                 .map(&:to_i)

    Rails.logger.info("[QUEUE][online] Online IDs: #{agent_ids.inspect}")

    stats = agent_ids.map do |id|
      active_count = Conversation
                       .where(account_id: account.id, assignee_id: id)
                       .where.not(status: :resolved)
                       .count

      last_closed = Conversation
                      .where(account_id: account.id, assignee_id: id, status: :resolved)
                      .order(updated_at: :desc)
                      .pick(:updated_at) || Time.at(0)

      Rails.logger.info("[QUEUE][online] Agent #{id}: active=#{active_count}, last_closed=#{last_closed}")

      { id: id, active: active_count, last_closed: last_closed }
    end

    sorted = stats
               .sort_by { |a| [a[:active], a[:last_closed]] }
               .map { |a| a[:id] }

    Rails.logger.info("[QUEUE][online] Sorted agent list: #{sorted.inspect}")
    sorted
  end

  def assign_from_queue(inbox_id, _agent = nil)
    Rails.logger.info("[QUEUE][assign] Start assign_from_queue")

    unless account.queue_enabled?
      Rails.logger.info("[QUEUE][assign] Skip: queue disabled")
      return nil
    end

    group = priority_group_for_inbox(inbox_id)

    entry = ConversationQueue.for_account(account.id).for_priority_group(group).waiting.order(:position, :queued_at).first
    
    unless entry
      Rails.logger.info("[QUEUE][assign] Skip: no queue entries")
      return nil
    end

    cid = entry.conversation_id
    Rails.logger.info("[QUEUE][assign][conv=#{cid}] Pick best agent")

    best_agent = pick_best_agent_for_conversation(entry.conversation)

    unless best_agent
      Rails.logger.info("[QUEUE][assign][conv=#{cid}] No suitable agent")
      return nil
    end

    Rails.logger.info("[QUEUE][assign][conv=#{cid}] Assigning to agent #{best_agent.id}")
    assign_entry(entry, best_agent)
  end

  def pick_best_agent_for_conversation(conversation)
    cid = conversation.id
    Rails.logger.info("[QUEUE][pick][conv=#{cid}] Selecting best agent")

    online_agents_list.each do |id|
      agent = User.find_by(id: id)
      Rails.logger.info("[QUEUE][pick][conv=#{cid}] Check agent #{id}: exists=#{agent.present?}")
      next unless agent

      allowed = conversation_allowed_for_agent?(conversation, agent)
      available = agent_available?(agent)

      Rails.logger.info("[QUEUE][pick][conv=#{cid}] Agent #{id}: allowed=#{allowed}, available=#{available}")

      next unless allowed && available

      Rails.logger.info("[QUEUE][pick][conv=#{cid}] Selected agent #{id}")
      return agent
    end

    Rails.logger.info("[QUEUE][pick][conv=#{conversation.id}] No agent found")
    nil
  end

  def remove_from_queue(conversation)
    cid = conversation.id
    Rails.logger.info("[QUEUE][remove][conv=#{cid}] Removing from queue")

    entry = ConversationQueue.find_by(conversation_id: cid)
    unless entry&.waiting?
      Rails.logger.info("[QUEUE][remove][conv=#{cid}] Skip: not in waiting state")
      return
    end

    entry.update!(status: :left, left_at: Time.current)

    Rails.logger.info("[QUEUE][remove][conv=#{cid}] Updating statistics")
    wait_time = entry.wait_time_seconds
    QueueStatistic.update_statistics_for(
      account.id,
      wait_time_seconds: wait_time,
      left: true
    )
  end

  def next_in_queue(inbox_id)
    group = priority_group_for_inbox(inbox_id)

    Rails.logger.info("[QUEUE][next] Fetching next conversation in queue for account #{account.id}")
    ConversationQueue.for_account(account.id).for_priority_group(group).waiting.first&.conversation
  end

  def queue_size(inbox_id)
    group = priority_group_for_inbox(inbox_id)

    size = ConversationQueue.for_account(account.id).for_priority_group(group).waiting.count
    Rails.logger.info("[QUEUE][size] Queue size=#{size} for account #{account.id}")
    size
  end

  def assign_specific_from_queue!(agent, conv_id)
    Rails.logger.info("[QUEUE][assign_specific][conv=#{conv_id}] Start assign_specific")

    unless account.queue_enabled?
      Rails.logger.info("[QUEUE][assign_specific][conv=#{conv_id}] Skip: queue disabled")
      return nil
    end

    unless agent_available?(agent)
      Rails.logger.info("[QUEUE][assign_specific][conv=#{conv_id}] Agent #{agent.id} unavailable")
      return nil
    end

    entry = ConversationQueue.find_by(conversation_id: conv_id, status: :waiting)

    unless entry
      Rails.logger.info("[QUEUE][assign_specific][conv=#{conv_id}] No waiting entry found")
      return nil
    end

    conversation = entry.conversation

    if !conversation.queued?
      Rails.logger.info("[QUEUE][assign_specific][conv=#{conv_id}] Skip: conversation not queued")
      return nil
    end

    if conversation.assignee_id.present?
      Rails.logger.info("[QUEUE][assign_specific][conv=#{conv_id}] Skip: already assigned")
      return nil
    end

    unless conversation_allowed_for_agent?(conversation, agent)
      Rails.logger.info("[QUEUE][assign_specific][conv=#{conv_id}] Skip: agent not allowed for inbox")
      return nil
    end

    Rails.logger.info("[QUEUE][assign_specific][conv=#{conv_id}] Assigning to agent #{agent.id}")
    assign_entry(entry, agent)
  end

  def agent_available?(agent)
    Rails.logger.info("[QUEUE][agent_available] Check agent #{agent&.id || 'nil'}")

    return false if agent.blank?

    statuses = OnlineStatusTracker.get_available_users(account.id) || {}
    online = statuses[agent.id.to_s] == "online"

    Rails.logger.info("[QUEUE][agent_available][agent=#{agent.id}] online=#{online}")
    return false unless online

    active_count = Conversation
      .where(account_id: account.id, assignee_id: agent.id)
      .where.not(status: :resolved)
      .count

    limit = effective_limit_for_agent(agent.id)
    available = limit.nil? || active_count < limit

    Rails.logger.info("[QUEUE][agent_available][agent=#{agent.id}] active=#{active_count}, limit=#{limit}, available=#{available}")

    available
  end

  def conversation_allowed_for_agent?(conversation, agent)
    cid = conversation.id
    allowed = InboxMember.exists?(inbox_id: conversation.inbox_id, user_id: agent.id)
    Rails.logger.info("[QUEUE][allowed][conv=#{cid}] Agent #{agent.id} allowed=#{allowed}")
    allowed
  end

  def in_queue?(conversation_id)
    exists = ConversationQueue.exists?(conversation_id: conversation_id, status: :waiting)
    Rails.logger.info("[QUEUE][in_queue][conv=#{conversation_id}] #{exists}")
    exists
  end

  private

  def priority_group_for_inbox(inbox_id)
    @priority_groups ||= {}
    @priority_groups[inbox_id] ||= Inbox.find(inbox_id).priority_group
  end  

  def effective_limit_for_agent(agent_id)
    Rails.logger.info("[QUEUE][limit][agent=#{agent_id}] Fetching limits")

    account_user = AccountUser.find_by(account_id: account.id, user_id: agent_id)

    if account_user&.active_chat_limit_enabled? && account_user.active_chat_limit.present?
      limit = account_user.active_chat_limit.to_i
      Rails.logger.info("[QUEUE][limit][agent=#{agent_id}] User limit=#{limit}")
      return limit
    end

    if account.active_chat_limit_enabled? && account.active_chat_limit_value.present?
      limit = account.active_chat_limit_value.to_i
      Rails.logger.info("[QUEUE][limit][agent=#{agent_id}] Account limit=#{limit}")
      return limit
    end

    Rails.logger.info("[QUEUE][limit][agent=#{agent_id}] No limits")
    nil
  end

  def assign_entry(entry, agent)
    cid = entry.conversation_id
    Rails.logger.info("[QUEUE][assign_entry][conv=#{cid}] Start assign to agent #{agent.id}")

    ConversationQueue.transaction do
      locked_entry = ConversationQueue.lock.find(entry.id)
      conversation = locked_entry.conversation

      if locked_entry.status == "assigned"
        Rails.logger.info("[QUEUE][assign_entry][conv=#{cid}] Skip: already assigned")
        return conversation
      end

      if conversation.assignee_id.present?
        Rails.logger.info("[QUEUE][assign_entry][conv=#{cid}] Skip: conversation already has assignee #{conversation.assignee_id}")
        return conversation
      end

      unless agent_limit_available?(agent)
        Rails.logger.info("[QUEUE][assign_entry][conv=#{cid}] Abort: agent #{agent.id} exceeds limit")
        raise ActiveRecord::Rollback
      end

      Rails.logger.info("[QUEUE][assign_entry][conv=#{cid}] Updating queue entry to assigned")
      locked_entry.update!(
        status: :assigned,
        assigned_at: Time.current
      )

      Rails.logger.info("[QUEUE][assign_entry][conv=#{cid}] Updating conversation assignee")
      conversation.update!(
        assignee: agent,
        status: :open,
        updated_at: Time.current
      )

      Rails.logger.info("[QUEUE][assign_entry][conv=#{cid}] Update statistics")
      update_statistics(locked_entry)

      Rails.logger.info("[QUEUE][assign_entry][conv=#{cid}] Sending assigned notification")
      send_assigned_notification(conversation)

      Rails.logger.info("[QUEUE][assign_entry][conv=#{cid}] Completed")
      conversation
    end
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => e
    Rails.logger.error("[QUEUE][assign_entry][conv=#{entry.conversation_id}] Exception: #{e.class} #{e.message}")
    nil
  end

  def agent_limit_available?(agent)
    limit = effective_limit_for_agent(agent.id)
    Rails.logger.info("[QUEUE][limit_check][agent=#{agent.id}] limit=#{limit}")

    return true if limit.nil?

    active_chats = Conversation
      .where(account_id: account.id, assignee_id: agent.id)
      .where.not(status: :resolved)
      .lock("FOR UPDATE")
      .pluck(:id)

    available = active_chats.size < limit
    Rails.logger.info("[QUEUE][limit_check][agent=#{agent.id}] active=#{active_chats.size}, available=#{available}")

    available
  end

  def send_queue_notification(conversation)
    cid = conversation.id
    Rails.logger.info("[QUEUE][notify_queue][conv=#{cid}] Sending queue template")

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: 'Все операторы сейчас заняты. Мы подключим вас к свободному оператору, как только он освободится.'
    )
  rescue => e
    Rails.logger.error("[QUEUE][notify_queue][conv=#{cid}] Error: #{e.message}")
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
  end

  def send_assigned_notification(conversation)
    cid = conversation.id
    Rails.logger.info("[QUEUE][notify_assigned][conv=#{cid}] Sending assigned template")

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: 'Оператор подключился к диалогу.'
    )
  rescue => e
    Rails.logger.error("[QUEUE][notify_assigned][conv=#{cid}] Error: #{e.message}")
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
  end

  def update_statistics(entry)
    cid = entry.conversation_id
    Rails.logger.info("[QUEUE][stats][conv=#{cid}] Updating stats")

    wait_time = entry.wait_time_seconds

    QueueStatistic.update_statistics_for(
      account.id,
      wait_time_seconds: wait_time,
      assigned: true
    )
  end
end
