class Conversations::ActivityMessageJob < ApplicationJob
  queue_as :within_5_seconds

  def perform(conversation, message_params)
    conversation.messages.create!(message_params)
  end
end
