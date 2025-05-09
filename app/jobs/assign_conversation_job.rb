class AssignConversationJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, account_id, inbox_id, assignee)
    conversation = Conversation.find(conversation_id)

    # Create the assignment message
    conversation.messages.create!(
      account_id: account_id,
      sender: assignee,
      content: 'Someone from the team will get back to you shortly!',
      inbox_id: inbox_id,
      message_type: 'outgoing'
    )
    conversation.update!(assignee_id: nil)

    # Run auto assignment
    conversation.run_auto_assignment_for_web_widget_inbox
  end
end
