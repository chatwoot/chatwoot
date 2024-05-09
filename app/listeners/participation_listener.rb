class ParticipationListener < BaseListener
  include Events::Types

  def assignee_changed(event)
    conversation, _account = extract_conversation_and_account(event)
    conversation.conversation_participants.find_or_create_by!(user_id: conversation.assignee_id) if conversation.assignee_id.present?
  end
end
