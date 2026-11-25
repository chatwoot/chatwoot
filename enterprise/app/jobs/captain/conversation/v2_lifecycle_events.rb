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
      reason_category: :tool_failure,
      at: Time.current
    )
  end

  # The handoff field asks for a transfer only after the customer asked for a person or accepted one.
  def record_v2_reply_handoff
    Captain::ConversationEvents.handed_off(
      conversation: @conversation,
      assistant: @assistant,
      source: Captain::ConversationEvents::Sources::REPLY,
      reason_category: :customer_request,
      at: Time.current
    )
  end
end
