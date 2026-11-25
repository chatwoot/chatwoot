class Captain::ConversationEvents
  module Sources
    TOOL = 'tool'.freeze
    GENERATION_FAILURE = 'generation_failure'.freeze
    TIME_BASED = 'time_based'.freeze
    INFERENCE = 'inference'.freeze
    USAGE_LIMIT = 'usage_limit'.freeze
  end

  class << self
    def handed_off(conversation:, assistant:, source:, reason_category:, at:)
      dispatch(
        Events::Types::CAPTAIN_CONVERSATION_HANDED_OFF,
        at: at,
        conversation: conversation,
        assistant: assistant,
        source: source,
        reason_category: reason_category
      )
    end

    def resolved(conversation:, assistant:, source:, at:)
      dispatch(
        Events::Types::CAPTAIN_CONVERSATION_RESOLVED,
        at: at,
        conversation: conversation,
        assistant: assistant,
        source: source
      )
    end

    def response_completed(conversation:, assistant:, message:, at:)
      dispatch(
        Events::Types::CAPTAIN_RESPONSE_COMPLETED,
        at: at,
        conversation: conversation,
        assistant: assistant,
        message: message
      )
    end

    def response_failed(conversation:, assistant:, reason:, at:)
      dispatch(
        Events::Types::CAPTAIN_RESPONSE_FAILED,
        at: at,
        conversation: conversation,
        assistant: assistant,
        reason: reason
      )
    end

    private

    # Lifecycle events are secondary effects: a dispatch failure must never alter
    # the customer-facing Captain flow (blocking a response from being scheduled,
    # or turning an already-delivered reply into a spurious handoff).
    def dispatch(event_name, at:, **data)
      Rails.configuration.dispatcher.dispatch(event_name, at, data)
    rescue StandardError => e
      ChatwootExceptionTracker.new(e, account: data[:conversation]&.account).capture_exception
    end
  end
end
