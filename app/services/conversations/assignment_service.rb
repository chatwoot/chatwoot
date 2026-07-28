class Conversations::AssignmentService
  def initialize(conversation:, assignee_id:, assignee_type: nil)
    @conversation = conversation
    @assignee_id = assignee_id
    @assignee_type = assignee_type
  end

  def perform
    result = agent_bot_assignment? ? assign_agent_bot : assign_agent
    conversation.reload
    result
  end

  private

  attr_reader :conversation, :assignee_id, :assignee_type

  def assign_agent
    if cleared_assignee? && (bot = conversation.inbox.assignable_agent_bot)
      return assign_inbox_bot(bot)
    end

    conversation.assignee = assignee
    conversation.assignee_agent_bot = nil
    clear_panel_ia_state_attrs if assignee.present?
    conversation.save!
    assignee
  end

  def clear_panel_ia_state_attrs
    attrs = (conversation.custom_attributes || {}).dup
    attrs.delete(Flows::StateSyncService::ATTR_ESTADO)
    attrs.delete(Flows::StateSyncService::ATTR_LABEL)
    attrs.delete(Flows::StateSyncService::ATTR_UPDATED)
    conversation.custom_attributes = attrs
  end

  def cleared_assignee?
    assignee_id.blank? || assignee_id.to_i.zero?
  end

  def assign_inbox_bot(bot)
    conversation.assignee = nil
    conversation.assignee_agent_bot = bot
    conversation.save!
    bot
  end

  def assign_agent_bot
    return unless agent_bot
    return unless bot_assignable_to_inbox?(agent_bot)

    conversation.assignee = nil
    conversation.assignee_agent_bot = agent_bot
    conversation.save!
    agent_bot
  end

  def bot_assignable_to_inbox?(bot)
    inbox = conversation.inbox
    return false if inbox.blank? || bot.blank?

    inbox.assignable_agent_bot&.id == bot.id
  end

  def assignee
    @assignee ||= conversation.account.users.find_by(id: assignee_id)
  end

  def agent_bot
    @agent_bot ||= AgentBot.accessible_to(conversation.account).find_by(id: assignee_id)
  end

  def agent_bot_assignment?
    assignee_type.to_s == 'AgentBot'
  end
end
