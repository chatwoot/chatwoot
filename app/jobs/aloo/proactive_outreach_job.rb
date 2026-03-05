# frozen_string_literal: true

class Aloo::ProactiveOutreachJob < ApplicationJob
  queue_as :default
  retry_on RubyLLM::Error, wait: :polynomially_longer, attempts: 3

  def perform(conversation_id, event_context)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    Aloo::ProactiveOutreachService.new(conversation, event_context).call
  rescue StandardError => e
    Rails.logger.error("[Aloo::ProactiveOutreachJob] Error: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    raise
  end
end
