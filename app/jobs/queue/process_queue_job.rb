class Queue::ProcessQueueJob < ApplicationJob
  queue_as :default

  def perform(account_id, inbox_id)
    log_start(account_id)

    account = fetch_account_or_stop(account_id)
    return unless account

    queue_service = ChatQueue::QueueService.new(account: account)
    group = queue_service.priority_group_for_inbox(inbox_id)

    return if queue_empty?(queue_service, account, inbox_id)

    conv = fetch_conversation_or_stop(account, group)
    return unless conv

    log_conversation(conv)

    agent_ids_sorted = fetch_agents_list(queue_service)
    return if agent_ids_sorted.empty?

    agents = load_agents(agent_ids_sorted)
    log_loaded_agents(agent_ids_sorted, agents)

    try_assign(queue_service, conv, agent_ids_sorted, agents)

    schedule_or_stop(queue_service, inbox_id, account_id)
  end

  private

  def log_start(account_id)
    Rails.logger.info "[QUEUE][JOB] Start for account=#{account_id}"
  end

  def fetch_account_or_stop(account_id)
    account = find_active_account(account_id)
    unless account
      Rails.logger.info '[QUEUE][JOB] Stop: account not found or queue disabled'
      return nil
    end
    account
  end

  def queue_empty?(queue_service, account, inbox_id)
    size = queue_service.queue_size(inbox_id)
    Rails.logger.info "[QUEUE][JOB] Current queue_size=#{size} for account=#{account.id}"
    size.zero?
  end

  def fetch_conversation_or_stop(account, group)
    conv = ConversationQueue
           .for_account(account.id)
           .for_priority_group(group)
           .where(status: :waiting)
           .order(:position, :queued_at)
           .limit(1)
           .first

    unless conv
      Rails.logger.info '[QUEUE][JOB] No waiting conversations found'
      return nil
    end

    conv
  end

  def log_conversation(conv)
    Rails.logger.info "[QUEUE][JOB] Picked conversation_queue_id=#{conv.id} conv_id=#{conv.conversation_id} position=#{conv.position}"
  end

  def fetch_agents_list(queue_service)
    agent_ids_sorted = queue_service.online_agents_list
    Rails.logger.info "[QUEUE][JOB] Online agents sorted: #{agent_ids_sorted.inspect}"
    Rails.logger.info '[QUEUE][JOB] No agents available online' if agent_ids_sorted.empty?
    agent_ids_sorted
  end

  def load_agents(agent_ids_sorted)
    User.where(id: agent_ids_sorted).index_by(&:id)
  end

  def log_loaded_agents(_sorted_ids, agents)
    Rails.logger.info "[QUEUE][JOB] Loaded agents: #{agents.keys.inspect}"
  end

  def try_assign(queue_service, conv, agent_ids_sorted, agents)
    agent_ids_sorted.each do |agent_id|
      agent = agents[agent_id]

      unless agent
        Rails.logger.info "[QUEUE][JOB] Agent #{agent_id} is missing, skipping"
        next
      end

      Rails.logger.info "[QUEUE][JOB] Trying to assign conv_id=#{conv.conversation_id} to agent_id=#{agent.id}"

      if queue_service.assign_specific_from_queue!(agent, conv.conversation_id)
        Rails.logger.info "[QUEUE][JOB] SUCCESS assigned conv_id=#{conv.conversation_id} to agent_id=#{agent.id}"
        return true
      else
        Rails.logger.info "[QUEUE][JOB] FAIL assign to agent_id=#{agent.id}, trying next"
      end
    end

    false
  end

  def schedule_or_stop(queue_service, inbox_id, account_id)
    if queue_service.queue_size(inbox_id).positive?
      Rails.logger.info '[QUEUE][JOB] Queue still has items, scheduling next run'
      Queue::ProcessQueueJob.set(wait: 1.second).perform_later(account_id, inbox_id)
    else
      Rails.logger.info '[QUEUE][JOB] Queue empty after assign, stopping'
    end
  end

  def find_active_account(account_id)
    account = Account.find_by(id: account_id)
    return nil unless account&.queue_enabled?

    account
  end
end
