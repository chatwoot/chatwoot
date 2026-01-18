# frozen_string_literal: true

module Aloo
  module ContextHelpers
    # Set Aloo::Current context for testing
    # @param account [Account] The account
    # @param assistant [Aloo::Assistant] The assistant
    # @param conversation [Conversation] Optional conversation
    # @param contact [Contact] Optional contact (defaults to conversation.contact)
    # @param inbox [Inbox] Optional inbox (defaults to conversation.inbox)
    def set_aloo_context(account:, assistant:, conversation: nil, contact: nil, inbox: nil)
      Aloo::Current.account = account
      Aloo::Current.assistant = assistant
      Aloo::Current.conversation = conversation
      Aloo::Current.contact = contact || conversation&.contact
      Aloo::Current.inbox = inbox || conversation&.inbox
      Aloo::Current.request_id = SecureRandom.uuid
    end

    # Reset Aloo::Current context
    def reset_aloo_context
      Aloo::Current.reset
    end

    # Execute block with Aloo context, auto-reset after
    # @param options [Hash] Context options (account, assistant, conversation, etc.)
    # @yield Block to execute with context
    def with_aloo_context(**options)
      set_aloo_context(**options)
      yield
    ensure
      reset_aloo_context
    end

    # Check if context is properly set
    def aloo_context_valid?
      Aloo::Current.account.present? && Aloo::Current.assistant.present?
    end
  end
end

RSpec.configure do |config|
  config.include Aloo::ContextHelpers, aloo: true
  config.include Aloo::ContextHelpers, type: :job
  config.include Aloo::ContextHelpers, type: :service

  # Auto-reset Aloo context after each test tagged with aloo: true
  config.after(:each, aloo: true) do
    Aloo::Current.reset
  end

  config.after(:each, type: :job) do
    Aloo::Current.reset
  end
end
