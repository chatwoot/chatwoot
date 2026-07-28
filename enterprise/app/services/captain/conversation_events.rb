class Captain::ConversationEvents
  class << self
    def engaged(conversation:, assistant:, at:)
      dispatch(
        Events::Types::CAPTAIN_CONVERSATION_ENGAGED,
        at: at,
        conversation: conversation,
        assistant: assistant
      )
    end

    def handed_off(conversation:, assistant:, source:, at:, reason_category: nil)
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

    def dispatch(event_name, at:, **data)
      Rails.configuration.dispatcher.dispatch(event_name, at, data)
    end
  end
end
