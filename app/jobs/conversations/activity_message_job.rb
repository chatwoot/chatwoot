class Conversations::ActivityMessageJob < ApplicationJob
  queue_as :high

  def perform(conversation, message_params)
    Rails.logger.info("Message debugging: #{conversation} #{message_params}")
    conversation.messages.create!(message_params)
  end
end
