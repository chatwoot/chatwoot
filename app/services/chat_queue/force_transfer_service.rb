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
      content: I18n.t('conversations.activity.force_transfer.no_agents_available', locale: conversation.account.locale)
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

    min_load = agents_with_load.pluck(:active_count).min

    least_loaded = agents_with_load.select { |h| h[:active_count] == min_load }

    least_loaded.min_by { |h| h[:last_assigned_at] || Time.zone.at(0) }[:agent]
  end

  # rubocop:disable Metrics/CyclomaticComplexity -- online + access + limit filter
  def fetch_available_agents
    online_users = OnlineStatusTracker.get_available_users(conversation.account.id) || {}
    online_agent_ids = online_users
                       .select { |_id, status| status == 'online' }
                       .keys
                       .map(&:to_i)

    return [] if online_agent_ids.empty?

    allowed_agents = User.where(id: online_agent_ids).select do |agent|
      agent_has_access?(agent) && !agent_over_limit?(agent)
    end

    allowed_agents.reject { |agent| agent.id == conversation.assignee_id }
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def agent_has_access?(agent)
    inbox_ids = InboxMember.where(user_id: agent.id).pluck(:inbox_id)

    inbox_ids.include?(conversation.inbox_id)
  end

  def agent_over_limit?(agent)
    limit = ChatQueue::Agents::LimitsService.new(account: conversation.account).limit_for(agent.id)
    return false if limit.nil?

    active_conversations_count(agent.id) >= limit
  end

  def active_conversations_count(agent_id)
    Conversation
      .where(account_id: conversation.account.id, assignee_id: agent_id, status: :open)
      .count
  end

  def transfer_to_agent(target_agent)
    previous_assignee = conversation.assignee
    transferred = perform_transfer(target_agent, previous_assignee)
    return error_result('No available agents for transfer') unless transferred

    success_result(target_agent)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    error_result("Transfer failed: #{e.message}")
  end

  def perform_transfer(target_agent, previous_assignee)
    ActiveRecord::Base.transaction do
      Current.executed_by = current_user
      lock_transfer_records(target_agent)
      raise ActiveRecord::Rollback if agent_over_limit?(target_agent)

      remove_from_queue_if_needed
      conversation.update!(assignee: target_agent, status: :open, last_activity_at: Time.current)
      log_transfer(previous_assignee, target_agent)
      send_transfer_notification(target_agent)
      true
    end
  end

  def lock_transfer_records(target_agent)
    conversation.lock!
    ConversationQueue.lock.find_by(conversation_id: conversation.id)
    AccountUser.lock.find_by!(account_id: conversation.account_id, user_id: target_agent.id)
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
      "Initiated by: #{current_user.id}, " \
      "At: #{Time.current}"
    )
  end

  def send_transfer_notification(target_agent)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: I18n.t(
        'conversations.activity.force_transfer.transferred',
        agent_name: target_agent.name,
        locale: conversation.account.locale
      )
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
      .pick(:updated_at)
  end
end
