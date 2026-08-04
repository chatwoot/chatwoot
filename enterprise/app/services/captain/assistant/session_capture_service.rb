class Captain::Assistant::SessionCaptureService
  SCENARIO_AGENT_REGEX = /\A#{Captain::Scenario::HANDOFF_KEY_PREFIX}_(\d+)_/

  def initialize(assistant:, conversation:, run_result:, result_message:, credits_consumed:)
    @assistant = assistant
    @conversation = conversation
    @run_result = run_result
    @result_message = result_message
    @credits_consumed = credits_consumed
  end

  def capture
    # TODO: Capture failed runs once error-session semantics are defined. For now,
    # only successful runs that produce a customer-facing reply or handoff are recorded.
    return unless @run_result&.success?

    capture!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @assistant.account).capture_exception
    Rails.logger.error("[CAPTAIN][SessionCaptureService] Capture failed for conversation=#{@conversation.display_id}: #{e.message}")
  end

  def capture!
    model = @assistant.agent_model

    Captain::AgentSession.create!(
      assistant: @assistant,
      session_type: :assistant,
      subject: @conversation,
      result: result_message,
      llm_model: "#{Llm::Models.provider_for(model)}-#{model}",
      credits_consumed: @credits_consumed,
      faq_ids: metadata[:faq_ids] || [],
      used_faq_ids: metadata[:used_faq_ids] || [],
      cited_document_ids: cited_document_ids,
      document_ids: metadata[:document_ids] || [],
      scenario_ids: scenario_ids,
      run_context: current_turn_history
    )
  end

  private

  def context
    @run_result.context || {}
  end

  def metadata
    @metadata ||= context.dig(:state, :cw_metadata) || {}
  end

  def cited_document_ids
    return [] unless @assistant.config['feature_citation']

    citation_document_ids = (context.dig(:state, Captain::Assistant::CITATION_SOURCES_STATE_KEY) || {}).transform_keys(&:to_i)
    visible_citation_indexes = @assistant.customer_visible_citation_urls(citation_document_ids).keys
    stored_response_parts = result_message.additional_attributes.to_h[Captain::Assistant::ResponseParts::MESSAGE_ATTRIBUTE_KEY]
    response_parts = Captain::Assistant::ResponseParts.new(stored_response_parts)
    selected_citation_indexes = response_parts.to_a.flat_map { |part| part['citation_indexes'] }.uniq

    (selected_citation_indexes & visible_citation_indexes).filter_map { |index| citation_document_ids[index] }.uniq
  end

  # On handoff, HandoffTool records the private reason note it created; the session
  # attaches there so agents can inspect the generation path on the note itself.
  def result_message
    handoff_note || @result_message
  end

  def handoff_note
    note_id = metadata[:handoff_note_id]
    return if note_id.blank?

    @conversation.messages.find_by(id: note_id)
  end

  def scenario_ids
    ids = current_turn_history.filter_map do |message|
      next unless message[:role].to_s == 'assistant'

      message[:agent_name].to_s.match(SCENARIO_AGENT_REGEX)&.[](1)&.to_i
    end.uniq

    ids & @assistant.scenarios.where(id: ids).pluck(:id)
  end

  # Trim to the current turn: the last user message and everything after it
  # (assistant replies, tool calls/results, handoff hops).
  def current_turn_history
    history = Array(context[:conversation_history])
    turn_start_index = context[:captain_v2_turn_start_index] || history.rindex { |message| message[:role].to_s == 'user' } || 0
    current_turn = history[turn_start_index..]

    current_turn.map do |message|
      content = message[:content]
      content.is_a?(RubyLLM::Content) ? message.merge(content: content.to_h) : message
    end
  end
end
