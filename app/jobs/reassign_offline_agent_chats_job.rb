class ReassignOfflineAgentChatsJob < ApplicationJob
  queue_as :default

  def perform(agent_id)
    agent = User.find_by(id: agent_id)
    return unless agent

    conversations = Conversation.where(assignee_id: agent.id).where.not(status: :resolved)
    return if conversations.none?

    conversations.find_each do |conversation|
      reassign_conversation(conversation)
    end
  end

  private

  def reassign_conversation(conversation)
    allowed_agent_ids = online_agents_for(conversation)
    if allowed_agent_ids.empty?
      Rails.logger.warn("No online agents available for conversation #{conversation.id}")
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

  def online_agents_for(conversation)
    inbox = conversation.inbox
    return [] unless inbox

    account_id = conversation.account_id

    inbox.members
         .map(&:id)
         .uniq
         .reject { |id| id == conversation.assignee_id }
         .select { |id| OnlineStatusTracker.get_status(account_id, id) == 'online' }
  end
end
