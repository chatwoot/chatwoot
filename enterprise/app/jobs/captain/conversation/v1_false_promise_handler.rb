module Captain::Conversation::V1FalsePromiseHandler
  FUTURE_PROMISE_REPAIR_INSTRUCTION = <<~PROMPT.squish.freeze
    Internal instruction for the assistant, not a customer message: your previous draft promised future work after this
    message. Regenerate a replacement response now using the same conversation context and available tools. You may use
    tools now if needed. Do not promise delayed follow-up, later checking, monitoring, notifications, email, callbacks,
    or background escalation by yourself. Answer with what you can verify now, ask one concrete clarifying question, or
    offer a human handoff without claiming that it already happened.
  PROMPT

  private

  def repair_v1_false_promise_response(message_history)
    false_promise_detected = false
    return unless v1_false_promise_harness_enabled?
    return if v1_handoff_requested?

    detection = detect_v1_false_promise(message_history)
    return unless future_work_promise?(detection)

    false_promise_detected = true
    mark_v1_false_promise_handoff_fallback
    regenerate_v1_false_promise_response(message_history)
    inspect_v1_response_after_false_promise_repair(message_history)
  rescue StandardError => e
    mark_v1_false_promise_handoff_fallback if false_promise_detected
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    Rails.logger.warn(
      "[CAPTAIN][ResponseBuilderJob] V1 false promise harness failed for account=#{account.id} " \
      "conversation=#{@conversation.display_id}: #{e.class.name}: #{e.message}"
    )
  end

  def mark_v1_false_promise_handoff_fallback
    @response.merge!(
      'action' => 'handoff',
      'action_reason' => 'false_promise_detected',
      'action_source' => 'false_promise_harness'
    )
  end

  def regenerate_v1_false_promise_response(message_history)
    repair_message_history = message_history + [{ role: 'assistant', content: @response['response'] }]
    @response = Captain::Llm::AssistantChatService.new(assistant: @assistant, conversation: @conversation).generate_response(
      message_history: repair_message_history,
      additional_message: FUTURE_PROMISE_REPAIR_INSTRUCTION
    )
  end

  def inspect_v1_response_after_false_promise_repair(message_history)
    classify_v1_response_action(message_history) if conversation_pending?
    return unless conversation_pending?
    return if v1_handoff_requested?

    verify_v1_false_promise_repair(message_history)
  end

  def detect_v1_false_promise(message_history)
    detection = Captain::Llm::AssistantFalsePromiseService.new(
      assistant: @assistant,
      conversation: @conversation
    ).detect(message_history: message_history, assistant_response: @response['response'])

    log_v1_false_promise_detection(detection)
    detection
  end

  def verify_v1_false_promise_repair(message_history)
    detection = detect_v1_false_promise(message_history)
    return if safe_response?(detection)

    mark_v1_false_promise_handoff_fallback
  end

  def future_work_promise?(detection)
    detection['decision'] == 'future_work_promise'
  end

  def safe_response?(detection)
    detection['decision'] == 'safe'
  end

  def v1_false_promise_harness_enabled?
    ActiveModel::Type::Boolean.new.cast(account.captain_false_promise_harness_enabled)
  end

  def log_v1_false_promise_detection(detection)
    Rails.logger.info(
      "[CAPTAIN][ResponseBuilderJob] V1 false promise harness account=#{account.id} " \
      "conversation=#{@conversation.display_id} decision=#{detection['decision']} " \
      "reason=#{detection['reason']} model=#{detection['model']}"
    )
  end
end
