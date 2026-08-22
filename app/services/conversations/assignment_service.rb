class Conversations::AssignmentService
  pattr_initialize [:conversation, :assignee_id, :assignee_type]

  def perform
    assign_agent
  end

  private

  def assign_agent
    assignee = Current.account.users.find_by(id: assignee_id) if assignee_id.present?
    conversation.update!(assignee: assignee)
    assignee
  end
end
