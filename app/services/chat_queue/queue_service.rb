class ChatQueue::QueueService
  pattr_initialize [:account!]

  MAX_ASSIGN_CHECK = 200

  def schedule_queue_processing
    redis.set("queue:#{account.id}:process", 1, ex: 2, nx: true)
    Queue::ProcessQueueJob.perform_later(account.id)
  end

  def add_to_queue(conversation)
    return false unless account.queue_enabled?

    if conversation.assignee_id.present?
      conversation.update_column(:assignee_id, nil)
    end

    return false if in_queue?(conversation.id)
  
    seq = redis.incr(seq_key)
    redis.zadd(queue_key, seq, conversation.id)
  
    conversation.update!(status: :queued, assignee_id: nil)
    send_queue_notification(conversation)
    schedule_queue_processing
  
    true
  end  

  def online_agents_list
    online_users_map
      .select { |_id, status| status == 'online' }
      .keys
      .map(&:to_i)
  end
  
  def assign_from_queue(agent)
    return nil unless account.queue_enabled?
    return nil unless agent_available?(agent)

    allowed_inboxes = InboxMember.where(user_id: agent.id).pluck(:inbox_id)

    candidate_ids = redis.zrange(queue_key, 0, 50)

    candidate_ids.each do |conv_id|
      lock_key = "queue:#{account.id}:lock:conv:#{conv_id}"

      next unless redis.set(lock_key, 1, nx: true, ex: 5)

      conversation = Conversation.lock.find_by(id: conv_id)

      unless conversation&.queued? && conversation.assignee_id.nil?
        redis.del(lock_key)
        next
      end

      unless allowed_inboxes.include?(conversation.inbox_id)
        redis.del(lock_key)
        next
      end

      redis.zrem(queue_key, conv_id)

      updated = Conversation.where(
        id: conv_id,
        status: :queued,
        assignee_id: nil
      ).update_all(
        assignee_id: agent.id,
        status: :open,
        updated_at: Time.current
      )

      if updated > 0
        send_assigned_notification(conversation.reload)
        redis.del(lock_key)
        return conversation
      else
        redis.del(lock_key)
        next
      end
    end

    nil
  end

  def remove_from_queue(conversation)
    redis.zrem(queue_key, conversation.id)
    conversation.update!(status: :pending) if conversation.queued?
  end

  def next_in_queue
    conv_id = redis.zrange(queue_key, 0, 0)&.first
    Conversation.find_by(id: conv_id)
  end

  def queue_size
    redis.zcard(queue_key)
  end

  def assign_specific_from_queue!(agent, conv_id)
    agent_lock_key = "queue:#{account.id}:lock:agent:#{agent.id}"
    agent_locked = redis.set(agent_lock_key, 1, ex: 3, nx: true)
    return nil unless agent_locked

    return nil unless account.queue_enabled?
    return nil unless agent_available?(agent)

    conv_id = conv_id.to_i
    lock_key = "queue:#{account.id}:lock:conv:#{conv_id}"

    locked = redis.set(lock_key, 1, ex: 5, nx: true)
    return nil unless locked

    begin
      return nil unless in_queue?(conv_id)

      conversation = Conversation.lock.find_by(id: conv_id)
      return nil unless conversation&.queued?
      return nil if conversation.assignee_id.present?
      return nil unless conversation_allowed_for_agent?(conversation, agent)

      removed = redis.zrem(queue_key, conv_id)
      return nil if removed == 0

      return nil unless agent_available?(agent)
      
      current_active = Conversation
      .where(account_id: account.id)
      .where.not(status: :resolved)
      .where(assignee_id: agent.id)
      .count

      limit = effective_limit_for_agent(agent.id)

      if limit && current_active >= limit
        puts "[QUEUE_LIMIT] Agent #{agent.id} reached limit #{limit}, cannot assign #{conv_id}"
        return nil
      end

      updated = Conversation.where(
        id: conv_id,
        status: :queued,
        assignee_id: nil
      ).update_all(
        assignee_id: agent.id,
        status: :open,
        updated_at: Time.current
      )

      return nil if updated.zero?

      send_assigned_notification(conversation.reload)
      reset_caches_after_assign(agent.id)
      conversation

    ensure
      redis.del(lock_key)
      redis.del(agent_lock_key)
    end
  end

  def reset_caches_after_assign(agent_id)
    @active_counts = nil
    @online_map = nil
    @allowed_cache&.delete(agent_id)
    @limits_cache&.delete(agent_id)
  end

  def agent_available?(agent)
    return false if agent.blank?

    online_users = online_users_map
    return false unless online_users[agent.id.to_s] == 'online'

    active_counts = cached_active_counts
    current_count = active_counts[agent.id] || 0

    limit = effective_limit_for_agent(agent.id)
    limit.nil? || current_count < limit
  end

  def conversation_allowed_for_agent?(conversation, agent)
    inbox_id = conversation.inbox_id
  
    InboxMember.exists?(inbox_id: inbox_id, user_id: agent.id)
  end  
  
  def in_queue?(conversation_id)
    redis.zscore(queue_key, conversation_id).present?
  end

  private

  def redis
    @redis ||= $alfred.with { |r| r }
  end

  def queue_key
    "queue:#{account.id}"
  end

  def seq_key
    "queue:#{account.id}:seq"
  end

  def effective_limit_for_agent(agent_id)
    @limits_cache ||= {}
    return @limits_cache[agent_id] if @limits_cache.key?(agent_id)

    account_user = AccountUser.find_by(account_id: account.id, user_id: agent_id)

    limit =
      if account_user&.active_chat_limit_enabled? && account_user.active_chat_limit.present?
        account_user.active_chat_limit.to_i
      elsif account.active_chat_limit_enabled? && account.active_chat_limit_value.present?
        account.active_chat_limit_value.to_i
      end

    @limits_cache[agent_id] = limit
  end

  def cached_allowed_resources_for(agent_id)
    @allowed_cache ||= {}
  
    @allowed_cache[agent_id] ||= begin
      inbox_ids = Inbox.joins(:inbox_members)
                       .where(inbox_members: { user_id: agent_id }, account_id: account.id)
                       .pluck(:id)
  
      { inboxes: inbox_ids }
    end
  end

  def online_users_map
    @online_map ||= (OnlineStatusTracker.get_available_users(account.id) || {})
  end

  def cached_active_counts
    Conversation
      .where(account_id: account.id)
      .where.not(status: :resolved)
      .group(:assignee_id)
      .count
  end

  def any_available_agents?
    online_agents_list.any? do |agent_id|
      agent = User.find_by(id: agent_id)
      agent_available?(agent)
    end
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
end
