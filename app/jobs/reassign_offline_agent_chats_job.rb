class ReassignOfflineAgentChatsJob < ApplicationJob
  queue_as :default

  def perform(agent_id, account_id = nil)
    agent = User.find_by(id: agent_id)
    return unless agent

    conversations = Conversation
                    .where(assignee_id: agent.id)
                    .where.not(status: :resolved)
    conversations = conversations.where(account_id: account_id) if account_id.present?
    return if conversations.none?

    account = Account.find_by(id: account_id)
    return unless account

    agent_statuses = agent_statuses_for(account)

    online_agent_ids = agent_statuses.select { |_, status| status.to_s == 'online' }.keys

    if online_agent_ids.empty?
      Rails.logger.warn("All agents offline in account #{account.id} — unassigning #{conversations.size} conversations")
      # rubocop:disable Rails/SkipsModelValidations
      conversations.update_all(assignee_id: nil, updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations
      return
    end

    conversations.find_each do |conversation|
      reassign_conversation(conversation, agent_statuses)
    end
  end

  private

  def reassign_conversation(conversation, agent_statuses)
    allowed_agent_ids = online_agents_for(conversation, agent_statuses)

    if allowed_agent_ids.empty?
      Rails.logger.warn("No online agents for conversation #{conversation.id} — unassigning")
      conversation.update!(assignee_id: nil)
      return
    end

    AutoAssignment::AgentAssignmentService.new(
      conversation: conversation,
      allowed_agent_ids: allowed_agent_ids
    ).perform

    Rails.logger.info("Conversation #{conversation.id} reassigned")
  rescue StandardError => e
    Rails.logger.error("Failed to reassign conversation #{conversation.id}: #{e.message}")
  end

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
