class ChatQueue::Agents::AvailabilityService
  pattr_initialize [:account!]

  def available?(agent)
    log_initial_check(agent)
    return false if agent.blank?

    online = online?(agent)
    return false unless online

    active_count = active_conversations_count(agent)
    limit = fetch_limit(agent)
    available = limit.nil? || active_count < limit

    log_result(agent, active_count, limit, available)
    available
  end

  private

  def log_initial_check(agent)
    Rails.logger.info("[QUEUE][agent_available] Check agent #{agent&.id || 'nil'}")
  end

  def online?(agent)
    statuses = OnlineStatusTracker.get_available_users(account.id) || {}
    online = statuses[agent.id.to_s] == 'online'
    Rails.logger.info("[QUEUE][agent_available][agent=#{agent.id}] online=#{online}")
    online
  end

  def active_conversations_count(agent)
    Conversation
      .where(account_id: account.id, assignee_id: agent.id)
      .where.not(status: :resolved)
      .count
  end

  def fetch_limit(agent)
    ChatQueue::Agents::LimitsService.new(account: account).limit_for(agent.id)
  end

  def log_result(agent, active_count, limit, available)
    Rails.logger.info(
      "[QUEUE][agent_available][agent=#{agent.id}] active=#{active_count}, limit=#{limit}, available=#{available}"
    )
  end
end
