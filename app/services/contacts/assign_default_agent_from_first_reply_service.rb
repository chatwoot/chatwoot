class Contacts::AssignDefaultAgentFromFirstReplyService
  pattr_initialize [:message!]

  def perform
    return unless message.human_response? && !message.private?

    contact = message.conversation&.contact
    return if contact.blank?
    return if contact.assigned_agent_id.present?

    agent = resolve_agent
    return if agent.blank?
    return unless agent.is_a?(User)
    return if agent.id == contact.id

    contact.update!(assigned_agent: agent)
  end

  private

  # Returns the User that should own the contact. Never returns Bot, Contact,
  # Conversation, or any non-User object — that protects us from self-assignment
  # loops (bot talking to itself) and from type errors in update!.
  def resolve_agent
    sender = message.sender
    return sender if sender.is_a?(User) && sender.id.present?

    assignee = message.conversation&.assignee
    return assignee if assignee.is_a?(User) && assignee.id.present?

    nil
  end
end
