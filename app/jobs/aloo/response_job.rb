# frozen_string_literal: true

class Aloo::ResponseJob < ApplicationJob
  queue_as :default
  retry_on RubyLLM::Error, wait: :polynomially_longer, attempts: 3

  def perform(conversation_id, message_id)
    conversation = Conversation.find_by(id: conversation_id)
    message = Message.find_by(id: message_id)

    return unless conversation && message

    Aloo::ResponseService.new(conversation, message).call
  rescue StandardError => e
    Rails.logger.error("[Aloo::ResponseJob] Error: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    raise
  end
end
