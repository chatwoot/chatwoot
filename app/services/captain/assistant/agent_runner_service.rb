require 'agents'
require 'agents/instrumentation'

class Captain::Assistant::AgentRunnerService
  include Captain::Assistant::RunnerCallbacksHelper
  include Captain::Assistant::AgentRunResponse
  include Captain::Assistant::RunnerInstrumentationHelper
  include Captain::Assistant::TracePayloadHelper
  include Captain::Assistant::RunnerStateHelper

  attr_reader :last_run_result

  def initialize(assistant:, conversation: nil, callbacks: {}, source: nil, responding_to_message_id: nil, detected_language: nil) # rubocop:disable Metrics/ParameterLists
    # The agents runner builds RubyLLM agents lazily, so the LLM provider config
    # (API key / endpoint) must be applied before the first run or RubyLLM raises
    # "Missing configuration for ..." and the agent returns an empty response.
    Llm::Config.initialize!
    @assistant = assistant
    @conversation = conversation
    @callbacks = callbacks
    @source = source
    @responding_to_message_id = responding_to_message_id
    @detected_language = detected_language
    @handoff_tool_called = false
    @handoff_tool_completed = false
    @handoff_offer_pending = false
  end

  def generate_response(message_history: [])
    decision_trace_builder.reset!
    message_to_process, context = run_payload(message_history)
    @last_run_result = measure_agent_segment('agent_run') do
      runner.run(message_to_process, context: context, max_turns: @assistant.max_turns)
    end
    record_turn_start(@last_run_result)
    @last_run_result = measure_agent_segment('faq_answer_resolver') { resolve_placeholder_non_answer(@last_run_result, message_history) }
    if response_too_long?(@last_run_result)
      @last_run_result = measure_agent_segment('response_rewriter') { rewrite_oversized_response(@last_run_result) }
    end

    raise "Captain response exceeds the channel limit of #{message_length_limit} characters" if response_too_long?(@last_run_result)

    process_agent_result(@last_run_result)
  rescue StandardError => e
    handle_generation_error(e)
  end

  def response_discarded? = @response_discarded == true

  def handoff_completed? = @handoff_tool_completed == true

  # True when the handoff tool posted a consent offer instead of transferring.
  # The job uses this to avoid posting a transfer message and to keep the
  # conversation with the assistant while waiting for the customer's reply.
  def handoff_offer_pending? = @handoff_offer_pending == true

  def handoff_offer_message_id
    @last_run_result&.context&.dig(:state, :captain_v2_handoff_offer_message_id)
  end

  # Ordered list of decision nodes for the most recent run.
  def decision_trace
    @decision_trace_builder&.to_h || []
  end

  private

  # Time an LLM segment (the runner loop, FAQ resolution, or response rewriting)
  # so the next profile shows per-segment latency instead of one opaque block.
  # Logs the duration and, when OpenTelemetry is enabled, records it on the run's
  # root span so it lands in Langfuse alongside the existing captain_v2 traces.
  def measure_agent_segment(segment_name)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = yield
    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round(1)
    Rails.logger.info "[Captain V2] #{segment_name} took #{elapsed_ms}ms"
    record_segment_latency(segment_name, elapsed_ms, result)
    result
  end

  def record_segment_latency(segment_name, elapsed_ms, result)
    return unless ChatwootApp.otel_enabled?

    root_span = result&.context&.dig(:__otel_tracing, :root_span)
    root_span&.set_attribute("captain_v2.#{segment_name}_duration_ms", elapsed_ms.to_s)
  end

  # Surface an agent run failure: report to the exception tracker + Rails log,
  # persist to the Super Admin failure feed, and return the structured error
  # response so the conversation degrades to a human handoff.
  def handle_generation_error(error)
    # In rake/local runs, conversation may not be present, so account is optional here.
    ChatwootExceptionTracker.new(error, account: @conversation&.account).capture_exception
    Rails.logger.error "[Captain V2] AgentRunnerService error: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")

    Captain::Llm::FailureLogger.record(
      source: :agent,
      error: error,
      account_id: @assistant.account_id,
      assistant_id: @assistant.id,
      conversation_id: @conversation&.id
    )

    error_response(error)
  end

  def extract_last_user_message_text(message_history)
    last_user_msg = message_history.reverse.find { |msg| msg[:role] == 'user' }
    return '' if last_user_msg.blank?

    content = last_user_msg[:content]
    return content.to_s unless content.is_a?(Array)

    text, = Captain::OpenAiMessageBuilderService.extract_text_and_attachments(content)
    text.to_s
  end

  def build_context(message_history)
    conversation_history = message_history.map do |msg|
      content = msg[:content]
      # Preserve multimodal arrays (with image_url entries) as-is for the runner to restore with attachments.
      # Only extract text from non-array formats (hashes from agent structured output, plain strings).
      content = extract_text_from_content(content) unless content.is_a?(Array)

      {
        role: msg[:role].to_sym,
        content: content,
        agent_name: msg[:agent_name]
      }
    end

    {
      session_id: "#{@assistant.account_id}_#{@conversation&.display_id}",
      conversation_history: conversation_history,
      state: build_state
    }
  end

  def extract_last_user_message(message_history)
    last_user_msg = message_history.reverse.find { |msg| msg[:role] == 'user' }
    return '' if last_user_msg.blank?

    content = last_user_msg[:content]
    return extract_text_from_content(content) unless content.is_a?(Array)

    text, attachments = Captain::OpenAiMessageBuilderService.extract_text_and_attachments(content)
    return text if attachments.blank?

    RubyLLM::Content.new(text, attachments)
  end

  def message_history_without_last_user_message(message_history)
    last_user_index = message_history.rindex { |msg| msg[:role] == 'user' }
    return message_history if last_user_index.nil?

    message_history.reject.with_index { |_msg, index| index == last_user_index }
  end

  def extract_text_from_content(content)
    # Handle structured output from agents
    if content.is_a?(Hash)
      response_text = Captain::Assistant::ResponseParts.from_response(content).plain_text
      return response_text.presence || content.to_s
    end

    return content unless content.is_a?(Array)

    text_parts = content.select { |part| part[:type] == 'text' }.pluck(:text)
    text_parts.join(' ')
  end

  def build_and_wire_agents
    assistant_agent = @assistant.agent
    scenario_agents = @assistant.scenarios.enabled.map(&:agent)

    assistant_agent.register_handoffs(*scenario_agents) if scenario_agents.any?
    scenario_agents.each { |scenario_agent| scenario_agent.register_handoffs(assistant_agent) }

    [assistant_agent] + scenario_agents
  end

  def runner
    @runner ||= begin
      configured_runner = Agents::Runner.with_agents(*build_and_wire_agents)
      configured_runner = add_usage_metadata_callback(configured_runner)
      configured_runner = add_callbacks_to_runner(configured_runner) if @callbacks.any?
      configured_runner = decision_trace_builder.install(configured_runner)
      install_instrumentation(configured_runner)
      configured_runner
    end
  end

  # The model occasionally replies with a promise to investigate (e.g. "I'll
  # check our FAQ database...") instead of actually calling the FAQ tool. Detect
  # and resolve that so the customer receives a real answer.
  def resolve_placeholder_non_answer(run_result, message_history)
    return run_result unless placeholder_non_answer?(run_result)

    user_question = extract_last_user_message_text(message_history)
    faq_answer_resolver.resolve(user_question, run_result)
  end

  def placeholder_non_answer?(run_result)
    response_text = Captain::Assistant::ResponseParts.from_response(run_result.output).plain_text
    faq_answer_resolver.placeholder_non_answer?(response_text)
  end

  def faq_answer_resolver
    @faq_answer_resolver ||= Captain::Assistant::FaqAnswerResolver.new(
      assistant: @assistant,
      attribute_provider: Captain::Assistant::InstrumentationAttributeProvider.new(self)
    )
  end

  def decision_trace_builder
    @decision_trace_builder ||= Captain::Assistant::DecisionTraceBuilder.new(assistant: @assistant)
  end

  def run_payload(message_history)
    message_to_process = extract_last_user_message(message_history)
    context = build_context(message_history_without_last_user_message(message_history))
    enrich_context_with_trace_payload!(context, message_history, message_to_process)
    [message_to_process, context]
  end
end
