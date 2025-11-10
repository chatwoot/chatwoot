# frozen_string_literal: true

class AutoAssignConversationListener < BaseListener
  MESSAGE_THRESHOLD = 3

  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    return unless message.incoming?

    AutoAssignConversationJob.perform_later(conversation.id)
  end
end
