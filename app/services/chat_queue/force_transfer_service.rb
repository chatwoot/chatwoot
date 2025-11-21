class ChatQueue::ForceTransferService
  pattr_initialize [:conversation!, :current_user!]

  def perform
    return error_result('Conversation not found') unless conversation

    target_agent = find_least_loaded_agent
    unless target_agent
      log_no_agents_available
      send_no_agents_activity_message
      return error_result('No available agents for transfer')
    end

    transfer_to_agent(target_agent)
  end

  private

  def send_no_agents_activity_message
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: "Нет доступных операторов для перевода"
    )
  end

  def find_least_loaded_agent
    available_agents = fetch_available_agents
    return nil if available_agents.empty?

    agents_with_load = available_agents.map do |agent|
      {
        agent: agent,
        active_count: active_conversations_count(agent.id),
        last_assigned_at: last_assigned_at(agent.id)
      }
    end

    min_load = agents_with_load.map { |h| h[:active_count] }.min

    least_loaded = agents_with_load.select { |h| h[:active_count] == min_load }
  
    least_loaded.min_by { |h| h[:last_assigned_at] || Time.at(0) }[:agent]
  end

  def fetch_available_agents
    online_users = OnlineStatusTracker.get_available_users(conversation.account.id) || {}
    online_agent_ids = online_users
                       .select { |_id, status| status == 'online' }
                       .keys
                       .map(&:to_i)

    return [] if online_agent_ids.empty?

    allowed_agents = User.where(id: online_agent_ids).select do |agent|
      agent_has_access?(agent)
    end

    allowed_agents.reject { |agent| agent.id == conversation.assignee_id }
  end

  def agent_has_access?(agent)
    inbox_ids = InboxMember.where(user_id: agent.id).pluck(:inbox_id)
    team_ids = TeamMember.where(user_id: agent.id).pluck(:team_id)

    has_inbox = inbox_ids.include?(conversation.inbox_id)
    has_team  = !conversation.team_id.present? || team_ids.include?(conversation.team_id)

    has_inbox && has_team
  end

  def active_conversations_count(agent_id)
    Conversation
      .where(account_id: conversation.account.id, assignee_id: agent_id)
      .where.not(status: :resolved)
      .count
  end

  def transfer_to_agent(target_agent)
    previous_assignee = conversation.assignee

    ActiveRecord::Base.transaction do
      remove_from_queue_if_needed

      conversation.update!(
        assignee: target_agent,
        status: :open,
        updated_at: Time.current
      )

      log_transfer(previous_assignee, target_agent)

      send_transfer_notification(target_agent)
    end

    success_result(target_agent)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    error_result("Transfer failed: #{e.message}")
  end

  def remove_from_queue_if_needed
    queue_service = ChatQueue::QueueService.new(account: conversation.account)
    queue_service.remove_from_queue(conversation)
  end

  def log_transfer(from_agent, to_agent)
    Rails.logger.info(
      "[FORCE_TRANSFER] Account: #{conversation.account.id}, " \
      "Conversation: #{conversation.id}, " \
      "From: #{from_agent&.id || 'unassigned'}, " \
      "To: #{to_agent.id}, " \
      "Initiated by: #{current_user.id}, " \
      "At: #{Time.current}"
    )
  end

  def log_no_agents_available
    Rails.logger.warn(
      "[FORCE_TRANSFER][NO_AGENTS] Account: #{conversation.account.id}, " \
      "Conversation: #{conversation.id}, " \
      "Inbox: #{conversation.inbox_id}, " \
      "Team: #{conversation.team_id || 'none'}, " \
      "Initiated by: #{current_user.id}, " \
      "At: #{Time.current}"
    )
  end
  
  def send_transfer_notification(target_agent)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: "Чат переведен на оператора #{target_agent.name}"
    )
  end

  def success_result(agent)
    {
      success: true,
      agent: agent,
      message: "Chat successfully transferred to #{agent.name}"
    }
  end

  def error_result(message)
    {
      success: false,
      agent: nil,
      message: message
    }
  end

  def last_assigned_at(agent_id)
    Conversation
      .where(account_id: conversation.account.id, assignee_id: agent_id)
      .order(updated_at: :desc)
      .limit(1)
      .pluck(:updated_at)
      .first
  end  
end
