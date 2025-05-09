class ResolveConversationJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, account_id, inbox_id, assignee)
    conversation = Conversation.find(conversation_id)

    # Create the resolution message
    conversation.messages.create!(
      account_id: account_id,
      sender: assignee,
      content: 'Glad that we could help you 😀!',
      inbox_id: inbox_id,
      message_type: 'outgoing'
    )

    # Sleep for 2 seconds to ensure message processing
    sleep(2)

    # Resolve the conversation
    conversation.update!(status: :resolved)
  end
end
