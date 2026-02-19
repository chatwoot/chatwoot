# frozen_string_literal: true

module Aloo
  class Current < ActiveSupport::CurrentAttributes
    # Request-scoped context for Aloo agent operations
    attribute :account
    attribute :conversation
    attribute :assistant
    attribute :contact
    attribute :inbox
    attribute :request_id
    attribute :playground_mode
    attribute :conversation_history

    # Set context from a conversation
    def set_from_conversation(conversation)
      self.conversation = conversation
      self.account = conversation.account
      self.assistant = conversation.inbox&.aloo_assistant
      self.contact = conversation.contact
      self.inbox = conversation.inbox
      self.request_id = SecureRandom.uuid
    end

    # Reset all context
    def reset_context
      reset
    end

    # Check if context is properly set
    def context_valid?
      account.present? && conversation.present?
    end

    # Build context hash for logging/tracing
    def to_context_hash
      {
        account_id: account&.id,
        conversation_id: conversation&.id,
        assistant_id: assistant&.id,
        contact_id: contact&.id,
        inbox_id: inbox&.id,
        request_id: request_id
      }
    end
  end
end
