class Captain::Assistant::SessionCaptureService
  SCENARIO_AGENT_REGEX = /\A#{Captain::Scenario::HANDOFF_KEY_PREFIX}_(\d+)_/

  def initialize(assistant:, conversation:, run_result:, result_message:, **options)
    @assistant = assistant
    @conversation = conversation
    @run_result = run_result
    @result_message = result_message
    @credits_consumed = options.fetch(:credits_consumed)
    @capture_message_sources = options.fetch(:capture_message_sources, false)
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
    metadata = context.dig(:state, :cw_metadata) || {}

    session = Captain::AgentSession.create!(
      assistant: @assistant,
      session_type: :assistant,
      subject: @conversation,
      result: @result_message,
      llm_model: "#{Llm::Models.provider_for(model)}-#{model}",
      credits_consumed: @credits_consumed,
      faq_ids: metadata[:faq_ids] || [],
      document_ids: metadata[:document_ids] || [],
      scenario_ids: scenario_ids,
      run_context: current_turn_history
    )
    capture_message_sources(metadata) if @capture_message_sources
    session
  end

  private

  def context
    @run_result.context || {}
  end

  def scenario_ids
    ids = current_turn_history.filter_map do |message|
      next unless message[:role].to_s == 'assistant'

      message[:agent_name].to_s.match(SCENARIO_AGENT_REGEX)&.[](1)&.to_i
    end.uniq

    ids & @assistant.scenarios.where(id: ids).pluck(:id)
  end

  def capture_message_sources(metadata)
    sources = Array(metadata[:message_sources])
    return if sources.empty?

    document_ids = @assistant.documents.where(id: sources.pluck(:document_id)).pluck(:id)
    return if document_ids.empty?

    insert_message_sources(message_source_rows(sources, document_ids))
  end

  def message_source_rows(sources, document_ids)
    timestamp = Time.current
    sources.filter_map do |source|
      next unless document_ids.include?(source[:document_id])

      {
        account_id: @assistant.account_id,
        assistant_id: @assistant.id,
        conversation_id: @conversation.id,
        message_id: @result_message.id,
        document_id: source[:document_id],
        assistant_response_id: source[:assistant_response_id],
        created_at: timestamp,
        updated_at: timestamp
      }
    end
  end

  def insert_message_sources(rows)
    return if rows.empty?

    # rubocop:disable Rails/SkipsModelValidations
    Captain::MessageSource.insert_all(rows, unique_by: :idx_captain_message_sources_on_message_and_response)
    # rubocop:enable Rails/SkipsModelValidations
  end

  # Trim to the current turn: the last user message and everything after it
  # (assistant replies, tool calls/results, handoff hops).
  def current_turn_history
    history = Array(context[:conversation_history])
    last_user_index = history.rindex { |message| message[:role].to_s == 'user' }
    last_user_index ? history[last_user_index..] : history
  end
end
