module Enterprise::Conversations::AssignmentService
  def perform
    return super unless assignee_type.to_s == 'Captain::Assistant'
    return if conversation.inbox.external_bot_active?
    return unless conversation.inbox.captain_active?

    assign_ai_assignee(captain_assistant)
  end

  private

  def captain_assistant
    assistant = conversation.inbox.captain_assistant
    assistant if assistant&.id == assignee_id.to_i
  end
end
