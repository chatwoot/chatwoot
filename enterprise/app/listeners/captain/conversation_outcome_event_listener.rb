class Captain::ConversationOutcomeEventListener < BaseListener
  def captain_conversation_eligible(event)
    tracker(event).record_eligibility(at: event.timestamp)
  end

  def captain_conversation_handed_off(event)
    tracker(event).record_handoff(at: event.timestamp, reason_category: event.data[:reason_category])
  end

  def conversation_updated(event)
    return unless event.data[:changed_attributes]&.dig('status', 0) == 'resolved'

    tracker(event).record_reopen(at: event.timestamp)
  end

  private

  def tracker(event)
    Captain::ConversationOutcomeTracker.new(
      conversation: event.data[:conversation],
      assistant: event.data[:assistant]
    )
  end
end
