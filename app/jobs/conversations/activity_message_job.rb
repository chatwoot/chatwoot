class Conversations::ActivityMessageJob < ApplicationJob
  queue_as :high

  def perform(conversation, message_params)
    return unless conversation.inbox.activity_messages_enabled?

    conversation.messages.create!(message_params)
  end
end
