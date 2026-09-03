module Enterprise::Conversations::AssignmentService
  def perform
    return super unless assignee_type.to_s == 'Captain::Assistant'

    assistant = captain_assistant
    assign_ai_assignee(assistant)
  end

  private

  def captain_assistant
    assistant = conversation.inbox.captain_assistant
    assistant if assistant&.id == assignee_id.to_i
  end
end
