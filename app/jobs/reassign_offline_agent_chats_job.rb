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

    current_status = OnlineStatusTracker.get_status(account_id, agent.id)

    if current_status.to_s == 'online'
      Rails.logger.info "Agent #{agent_id} is online again - skipping reassignment"
      return
    end

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

  def create_system_message(conversation)
    system_user = AccountUser.where(account_id: conversation.account_id, role: :system).first
    agent = User.find_by(id: conversation.assignee_id)
    name = agent&.name || "неизвестного оператора"

    conversation.messages.create!(
      message_type: :activity,
      content: "Чат был снят с оператора #{name}, так как он перешёл в офлайн",
      account: conversation.account,
      inbox: conversation.inbox,
      sender: system_user
    )
  end

  def reassign_conversation(conversation, agent_statuses)
    allowed_agent_ids = online_agents_for(conversation, agent_statuses)
  
    if allowed_agent_ids.empty?
      Rails.logger.warn("No online agents for conversation #{conversation.id} — unassigning")
      conversation.update_columns(assignee_id: nil, updated_at: Time.current)
      return
    end
  
    create_system_message(conversation)
  
    service = AutoAssignment::AgentAssignmentService.new(
      conversation: conversation,
      allowed_agent_ids: allowed_agent_ids
    )
  
    assignee_before = conversation.assignee_id
  
    service.perform
  
    if conversation.assignee_id == assignee_before
      Rails.logger.warn("All agents reached limit for conversation #{conversation.id} — unassigning")
      conversation.update_columns(assignee_id: nil, updated_at: Time.current)
      return
    end
  
    Rails.logger.info("Conversation #{conversation.id} reassigned")
  
  rescue StandardError => e
    Rails.logger.error("Failed to reassign conversation #{conversation.id}: #{e.message}")
    conversation.update_columns(assignee_id: nil, updated_at: Time.current)
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
