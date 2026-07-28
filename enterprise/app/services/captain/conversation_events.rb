class Captain::ConversationEvents
  class << self
    def eligible(conversation:, assistant:, at:)
      dispatch(
        Events::Types::CAPTAIN_CONVERSATION_ELIGIBLE,
        at: at,
        conversation: conversation,
        assistant: assistant
      )
    end

    def handed_off(conversation:, assistant:, reason_category:, source:, at:)
      dispatch(
        Events::Types::CAPTAIN_CONVERSATION_HANDED_OFF,
        at: at,
        conversation: conversation,
        assistant: assistant,
        reason_category: reason_category,
        source: source
      )
    end

    private

    def dispatch(event_name, at:, **data)
      Rails.configuration.dispatcher.dispatch(event_name, at, data)
    end
  end
end
