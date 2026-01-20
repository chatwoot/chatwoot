class ReassignOfflineAgentChatsJob < ApplicationJob
  queue_as :default

  def perform(agent_id, account_id = nil)
    return if account_id.nil?

    agent = User.find_by(id: agent_id)
    return unless agent

    account = Account.find_by(id: account_id)
    return unless account

    return if OnlineStatusTracker.get_status(account_id, agent.id).to_s == 'online'

    conversations = conversations_for(agent, account_id)
    return if conversations.none?

    agent_statuses = agent_statuses_for(account)

    reassign_or_unassign(conversations, account, agent_statuses)
  end

  private

  def conversations_for(agent, account_id)
    scope = Conversation.where(assignee_id: agent.id)
                        .where.not(status: :resolved)
    account_id.present? ? scope.where(account_id: account_id) : scope
  end

  def reassign_or_unassign(conversations, account, agent_statuses)
    online_agents = agent_statuses.select { |_, s| s.to_s == 'online' }.keys

    if online_agents.empty?
      unassign_all(conversations, account)
    else
      conversations.find_each do |conversation|
        reassign_conversation(conversation, agent_statuses)
      end
    end
  end

  # rubocop:disable Rails/SkipsModelValidations
  def unassign_all(conversations, account)
    Rails.logger.warn("All agents offline in account #{account.id} — unassigning #{conversations.size} conversations")
    conversations.update_all(assignee_id: nil, updated_at: Time.current)
  end
  # rubocop:enable Rails/SkipsModelValidations

  def create_system_message(conversation)
    system_user = AccountUser.where(account_id: conversation.account_id, role: :system).first
    agent = User.find_by(id: conversation.assignee_id)
    name = agent&.name || 'неизвестного оператора'

    conversation.messages.create!(
      message_type: :activity,
      content: "Чат был снят с оператора #{name}, так как он перешёл в офлайн",
      account: conversation.account,
      inbox: conversation.inbox,
      sender: system_user
    )
  end

  def reassign_conversation(conversation, agent_statuses)
    allowed = online_agents_for(conversation, agent_statuses)

    return unassign(conversation, 'No online agents') if allowed.empty?

    create_system_message(conversation)

    previous = conversation.assignee_id
    AutoAssignment::AgentAssignmentService.new(
      conversation: conversation,
      allowed_agent_ids: allowed
    ).perform

    return unassign(conversation, 'All agents reached limit') if conversation.assignee_id == previous

    Rails.logger.info("Conversation #{conversation.id} reassigned")
  rescue StandardError => e
    Rails.logger.error("Failed to reassign conversation #{conversation.id}: #{e.message}")
    unassign(conversation, 'Error')
  end

  # rubocop:disable Rails/SkipsModelValidations
  def unassign(conversation, reason)
    Rails.logger.warn("#{reason} for conversation #{conversation.id} — unassigning")
    conversation.update_columns(assignee_id: nil, updated_at: Time.current)
  end
  # rubocop:enable Rails/SkipsModelValidations

  def online_agents_for(conversation, agent_statuses)
    inbox = conversation.inbox
    return [] unless inbox

    inbox.members
         .map(&:id)
         .uniq
         .reject { |id| id == conversation.assignee_id }
         .select { |id| agent_statuses[id].to_s == 'online' }
  end

  def agent_statuses_for(account)
    account.users.map do |u|
      status = OnlineStatusTracker.get_status(account.id, u.id)

      if status.nil?
        status = u.account_users.find_by(account: account)&.auto_offline? ? 'offline' : 'online'
      end

      [u.id, status]
    end.to_h
  end
end
