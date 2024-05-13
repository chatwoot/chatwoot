class Conversations::ActivityMessageJob < ApplicationJob
  queue_as :high

  def perform(conversation, message_params)
    begin
      conversation.messages.create!(message_params)
    rescue StandardError => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.first
    end
  end
end
