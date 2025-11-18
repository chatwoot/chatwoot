# frozen_string_literal: true

class AutoAssignConversationListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    return unless message.incoming?

    AutoAssignConversationJob.perform_later(conversation.id)
  end
end
