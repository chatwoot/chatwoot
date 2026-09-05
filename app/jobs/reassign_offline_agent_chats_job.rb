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

    reassign_or_unassign(conversations, account)
  end

  private

  def conversations_for(agent, account_id)
    scope = Conversation.where(assignee_id: agent.id)
                        .where.not(status: :resolved)
    account_id.present? ? scope.where(account_id: account_id) : scope
  end

  def reassign_or_unassign(conversations, account)
    if online_agent_ids_for(account.id).empty?
      unassign_all(conversations, account)
    else
      conversations.find_each do |conversation|
        reassign_conversation(conversation)
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

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity -- queue vs. auto-assignment fallback with error handling
  def reassign_conversation(conversation)
    allowed = online_agents_for(conversation)
    return unassign(conversation, 'No online agents') if allowed.empty?

    create_system_message(conversation)
    previous_assignee_id = conversation.assignee_id

    reassigned = if conversation.account.queue_enabled?
                   reassign_via_queue(conversation)
                 else
                   reassign_via_auto_assignment(conversation, allowed)
                 end

    return if reassigned

    enqueue_for_reassignment(conversation) if conversation.account.queue_enabled?
    unassign(conversation, 'All agents reached limit') if conversation.reload.assignee_id == previous_assignee_id

    Rails.logger.info("Conversation #{conversation.id} reassigned") if conversation.assignee_id.present?
  rescue StandardError => e
    Rails.logger.error("Failed to reassign conversation #{conversation.id}: #{e.message}")
    enqueue_for_reassignment(conversation) if conversation.account.queue_enabled?
    unassign(conversation, 'Error')
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def reassign_via_auto_assignment(conversation, allowed)
    AutoAssignment::AgentAssignmentService.new(
      conversation: conversation,
      allowed_agent_ids: allowed
    ).perform

    conversation.reload.assignee_id.present? && allowed.include?(conversation.assignee_id)
  end

  def reassign_via_queue(conversation)
    conversation.update!(assignee_id: nil)
    conversation.reload

    agent = ChatQueue::Agents::SelectorService.new(account: conversation.account).pick_best_agent_for(conversation)
    if agent
      conversation.update!(assignee: agent, status: :open)
      Rails.logger.info("Conversation #{conversation.id} reassigned via queue to agent #{agent.id}")
      return true
    end

    ChatQueue::QueueService.new(account: conversation.account).add_to_queue(conversation)
    Rails.logger.info("Conversation #{conversation.id} added to queue after offline unassign")
    true
  end

  def enqueue_for_reassignment(conversation)
    return if conversation.queued?
    return if conversation.assignee_id.present?

    ChatQueue::QueueService.new(account: conversation.account).add_to_queue(conversation)
  end

  # rubocop:disable Rails/SkipsModelValidations
  def unassign(conversation, reason)
    Rails.logger.warn("#{reason} for conversation #{conversation.id} — unassigning")
    conversation.update_columns(assignee_id: nil, updated_at: Time.current)
  end
  # rubocop:enable Rails/SkipsModelValidations

  def online_agents_for(conversation)
    inbox = conversation.inbox
    return [] unless inbox

    online_ids = online_agent_ids_for(conversation.account_id)
    inbox.members
         .map(&:id)
         .uniq
         .reject { |id| id == conversation.assignee_id }
         .select { |id| online_ids.include?(id) }
  end

  def online_agent_ids_for(account_id)
    (OnlineStatusTracker.get_available_users(account_id) || {})
      .select { |_id, status| status == 'online' }
      .keys
      .map(&:to_i)
  end
end
