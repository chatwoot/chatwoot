class Conversations::AssignmentService
  def initialize(conversation:, assignee_id:, assignee_type: nil, reopen: false)
    @conversation = conversation
    @assignee_id = assignee_id
    @assignee_type = assignee_type
    @reopen = reopen
  end

  def perform
    agent_bot_assignment? ? assign_agent_bot : assign_agent
  end

  private

  attr_reader :conversation, :assignee_id, :assignee_type, :reopen

  def assign_agent
    conversation.with_lock do
      reopen_conversation if (reopen && assignee.present?) || (open_on_assignment? && conversation.pending?)
      conversation.assignee = assignee
      conversation.ai_assignee = nil
      conversation.save!
    end
    assignee
  end

  def assign_agent_bot
    assign_ai_assignee(agent_bot)
  end

  def reopen_conversation
    conversation.waiting_since = Time.current if conversation.pending? && conversation.waiting_since.blank?
    conversation.status = :open
  end

  def open_on_assignment?
    assignee.present? && conversation.ai_assignee_type.present?
  end

  def assign_ai_assignee(ai_assignee)
    return unless ai_assignee

    conversation.with_lock do
      conversation.assignee = nil
      conversation.ai_assignee = ai_assignee
      conversation.status = :pending
      conversation.save!
    end
    ai_assignee
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

Conversations::AssignmentService.prepend_mod_with('Conversations::AssignmentService')
