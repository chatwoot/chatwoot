class Conversations::PrivateNoteVisibility
  # Conservative rules until a dedicated NotePolicy exists:
  # - account administrators see every note
  # - the note's author always sees their own note
  # - the conversation assignee and team members see notes for context
  def self.allowed?(user:, message:, conversation: message.conversation)
    return false if user.blank?
    return false if message.account_id != conversation.account_id

    account_user = conversation.account.account_users.find_by(user_id: user.id)
    return true if account_user&.administrator?

    return true if message.sender_type == 'User' && message.sender_id == user.id

    assigned = conversation.assignee_id == user.id
    on_team = conversation.team_id.present? && user.teams.exists?(id: conversation.team_id)
    assigned || on_team
  end
end
