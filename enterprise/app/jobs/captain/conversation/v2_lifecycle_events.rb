module Captain::Conversation::V2LifecycleEvents
  private

  def v2_generation_errored?
    @response['error'].present?
  end

  def record_v2_response_completed(message)
    Captain::ConversationEvents.response_completed(
      conversation: @conversation,
      assistant: @assistant,
      message: message,
      at: Time.current
    )
  end

  def record_v2_response_failure(reason)
    Captain::ConversationEvents.response_failed(conversation: @conversation, assistant: @assistant, reason: reason, at: Time.current)
  end

  def record_v2_failure_handoff(source:)
    Captain::ConversationEvents.handed_off(
      conversation: @conversation,
      assistant: @assistant,
      source: source,
      reason_category: source == Captain::ConversationEvents::Sources::GENERATION_FAILURE ? :generation_failure : :tool_failure,
      at: Time.current
    )
  end
end
