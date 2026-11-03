# Logs the numbers in a turn's draft answer that no tool result supports. The draft is not sent back to the model,
# because a replay over saved answers flagged more correct numbers than wrong ones. Included by
# Captain::Copilot::TurnService, which provides the run and complete_loop.
module Captain::Copilot::NumberChecking
  private

  def complete_with_number_check(llm)
    complete_loop(llm).tap { |outcome| log_unsupported_numbers(llm) if outcome == :complete }
  end

  def log_unsupported_numbers(llm)
    draft = parse_json_response(llm.messages.last.content)['content'].to_s
    gaps = Captain::Copilot::NumberCheck.new(known_texts).unsupported(draft)
    Rails.logger.info "[Copilot] run #{@run.id} number check found #{gaps.size} unsupported numbers: #{gaps.pluck(:number).join(', ')}"
  end

  # Every tool result in the thread, and the thread's messages, since an answer may repeat a number an earlier turn found.
  # JSON.generate keeps characters such as & as they are, where to_json escapes them, so links match their tool results.
  def known_texts
    results = CopilotToolCall.of_thread(@run.copilot_thread_id).pluck(:result)
    messages = @run.copilot_thread.copilot_messages.where(message_type: %w[user assistant]).pluck(:message)
    (results + messages).map { |value| JSON.generate(value) }
  end

  def model_calls
    @run.transcript.fetch('messages', []).count { |message| message['role'] == 'assistant' }
  end
end
