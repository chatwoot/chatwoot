class ChatQueue::QueueService
  pattr_initialize [:account!]

  def add_to_queue(conversation)
    validator = ChatQueue::Queue::ValidationService.new(account: account)
    return false unless validator.valid_for_queue?(conversation)

    entry_service.prepare_for_queue!(conversation)
    true
  end

  def assign_from_queue(inbox_id)
    return log_queue_disabled unless account.queue_enabled?

    entry = ChatQueue::Queue::FetchService.new(account: account).fetch_queue_entry(inbox_id)
    return nil unless entry

    selector = ChatQueue::Agents::SelectorService.new(account: account)
    agent = selector.pick_best_agent_for(entry.conversation)
    return log_no_agent(entry.conversation_id) unless agent

    assign_entry(entry, agent)
  end

  def assign_specific_from_queue!(agent, conv_id)
    return log_queue_disabled_specific(conv_id) unless account.queue_enabled?
    return log_agent_unavailable(conv_id, agent) unless agent_available?(agent)

    entry = ChatQueue::Queue::FetchService.new(account: account).fetch_specific_entry(conv_id)
    return nil unless entry

    conversation = entry.conversation
    perms = ChatQueue::Agents::PermissionsService.new(account: account)
    return log_not_allowed(conv_id, agent) unless perms.allowed?(conversation, agent)

    assign_entry(entry, agent)
  end

  def remove_from_queue(conversation)
    ChatQueue::Queue::RemovalService.new(account: account, conversation: conversation).remove!
  end

  def online_agents_list
    ChatQueue::Agents::OnlineAgentsService.new(account: account).list
  end

  def queue_size(inbox_id)
    fetch_service.queue_size(inbox_id)
  end

  def priority_group_for_inbox(inbox_id)
    fetch_service.priority_group_for_inbox(inbox_id)
  end

  private

  def entry_service
    @entry_service ||= ChatQueue::Queue::EntryService.new(account: account)
  end

  def fetch_service
    @fetch_service ||= ChatQueue::Queue::FetchService.new(account: account)
  end

  def agent_available?(agent)
    ChatQueue::Agents::AvailabilityService.new(account: account).available?(agent)
  end

  def assign_entry(entry, agent)
    ChatQueue::Queue::AssignmentService.new(account: account, entry: entry, agent: agent).assign!
  end

  def log_queue_disabled
    Rails.logger.info('[QUEUE][assign] Queue disabled')
    nil
  end

  def log_queue_disabled_specific(conv_id)
    Rails.logger.info("[QUEUE][assign][conv=#{conv_id}] Queue disabled")
    nil
  end

  def log_agent_unavailable(conv_id, agent)
    Rails.logger.info("[QUEUE][assign][conv=#{conv_id}] Agent #{agent&.id} unavailable")
    nil
  end

  def log_not_allowed(conv_id, agent)
    Rails.logger.info("[QUEUE][assign][conv=#{conv_id}] Agent #{agent.id} not allowed")
    nil
  end

  def log_no_agent(conv_id)
    Rails.logger.info("[QUEUE][assign][conv=#{conv_id}] No agent selected")
    nil
  end
end
