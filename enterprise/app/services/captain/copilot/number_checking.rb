# Checks the numbers in a turn's draft answer once, in code, before the agent sees it. Included by
# Captain::Copilot::TurnService, which provides the run, the transcript and MAX_MODEL_CALLS.
module Captain::Copilot::NumberChecking
  private

  def complete_with_number_check(llm)
    outcome = complete_loop(llm)
    outcome == :complete && revise_numbers?(llm) ? complete_loop(llm) : outcome
  end

  # The flag is saved before the note is added, so a resumed turn never checks twice.
  def revise_numbers?(llm)
    return false if @run.context['numbers_checked']

    gaps = unsupported_numbers(parse_json_response(llm.messages.last.content)['content'].to_s)
    return false if gaps.empty? || model_calls >= self.class::MAX_MODEL_CALLS

    llm.add_message(role: :user, content: number_note(gaps))
    @transcript.save(@token)
    true
  end

  def unsupported_numbers(draft)
    gaps = Captain::Copilot::NumberCheck.new(known_texts).unsupported(draft)
    @run.with_lease(@token) { @run.update!(context: @run.context.merge('numbers_checked' => true)) }
    Rails.logger.info "[Copilot] run #{@run.id} number check found #{gaps.size} unsupported numbers: #{gaps.pluck(:number).join(', ')}"
    gaps
  end

  # Every tool result in the thread, and the thread's messages, since an answer may repeat a number an earlier turn found.
  # JSON.generate keeps characters such as & as they are, where to_json escapes them, so links match their tool results.
  def known_texts
    results = CopilotToolCall.joins(:copilot_run).where(copilot_runs: { copilot_thread_id: @run.copilot_thread_id }).pluck(:result)
    messages = @run.copilot_thread.copilot_messages.where(message_type: %w[user assistant]).pluck(:message)
    (results + messages).map { |value| JSON.generate(value) }
  end

  def number_note(gaps)
    lines = gaps.map { |gap| "- #{gap[:number]} in: #{gap[:sentence]}" }
    "Copilot's own check, not a message from the agent: these numbers in your draft do not appear in any tool result and do not " \
      "follow from them by a sum, difference, ratio or percentage.\n#{lines.join("\n")}\n" \
      'Check each with a tool, or remove it. Then give the full answer again, without mentioning this check.'
  end

  def model_calls
    @run.transcript.fetch('messages', []).count { |message| message['role'] == 'assistant' }
  end
end
