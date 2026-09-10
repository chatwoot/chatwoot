module Enterprise::Conversations::AssignmentService
  def perform
    return super unless assignee_type.to_s == 'Captain::Assistant'
    return unless conversation.account.feature_enabled?('captain_integration')

    assign_ai_assignee(captain_assistant)
  end

  private

  def open_on_assignment?
    super || conversation.ai_assignee_type == 'Captain::Assistant'
  end

  def captain_assistant
    assistant = conversation.inbox.captain_assistant
    assistant if assistant&.id == assignee_id.to_i
  end
end
