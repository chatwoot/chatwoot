class Captain::ConversationOutcomeEventListener < BaseListener
  def captain_conversation_eligible(event)
    tracker(event).record_eligibility(at: event.timestamp)
  end

  def captain_conversation_handed_off(event)
    outcome_tracker = tracker(event)
    outcome_tracker.record_eligibility(at: event.timestamp)
    outcome_tracker.record_handoff(at: event.timestamp, reason_category: event.data[:reason_category])
  end

  private

  def tracker(event)
    Captain::ConversationOutcomeTracker.new(
      conversation: event.data[:conversation],
      assistant: event.data[:assistant]
    )
  end
end
