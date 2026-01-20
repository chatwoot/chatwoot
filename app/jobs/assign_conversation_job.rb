class AssignConversationJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, account_id, inbox_id, assignee)
    conversation = Conversation.find(conversation_id)
    inbox = conversation.inbox

    # Only send default message if custom no_agent_message is not enabled
    # When no_agent_message is enabled, the AgentAssignmentService will send the custom message
    unless inbox.no_agent_message_enabled?
      conversation.messages.create!(
        account_id: account_id,
        sender: assignee,
        content: 'Someone from the team will get back to you shortly!',
        inbox_id: inbox_id,
        message_type: 'outgoing'
      )
    end

    conversation.update!(assignee: nil)

    # Run auto assignment
    conversation.run_auto_assignment_for_web_widget_inbox
  end
end
