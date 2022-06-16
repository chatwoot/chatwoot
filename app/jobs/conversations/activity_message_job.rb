class Conversations::ActivityMessageJob < ApplicationJob
  queue_as :default

  def perform(conversation, message_params)
    conversation.messages.create(message_params)
  end
end
