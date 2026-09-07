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
      account.queue_enabled? ? queue_all(conversations, account) : unassign_all(conversations, account)
    else
      conversations.find_each do |conversation|
        reassign_conversation(conversation)
      end
    end
  end

  # With queueing on, park the chats in the queue so they are picked up by the AccountUser
  # callback as soon as an agent comes back online.
  def queue_all(conversations, account)
    Rails.logger.warn("All agents offline in account #{account.id} — queueing #{conversations.size} conversations")
    conversations.find_each do |conversation|
      create_system_message(conversation)
      enqueue_for_reassignment(conversation) || unassign(conversation, 'No online agents')
    rescue StandardError => e
      Rails.logger.error("Failed to queue conversation #{conversation.id}: #{e.message}")
      unassign(conversation, 'Error')
    end
  end

  # Goes through the model so close_previous_agent_on_reassign closes the agent's participant
  # (chat-duration reporting) instead of a callback-less update_all.
  def unassign_all(conversations, account)
    Rails.logger.warn("All agents offline in account #{account.id} — unassigning #{conversations.size} conversations")
    conversations.find_each { |conversation| conversation.update!(assignee_id: nil) }
  end

  def create_system_message(conversation)
    agent = User.find_by(id: conversation.assignee_id)
    name = agent&.name || I18n.t('conversations.activity.assignee.unknown_agent')

    conversation.messages.create!(
      message_type: :activity,
      content: I18n.t('conversations.activity.assignee.unassigned_offline', agent_name: name),
      account: conversation.account,
      inbox: conversation.inbox
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
    return true if conversation.queued?

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
