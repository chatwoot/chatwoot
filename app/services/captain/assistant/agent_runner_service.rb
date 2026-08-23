require 'agents'
require 'agents/instrumentation'

class Captain::Assistant::AgentRunnerService
  include Captain::Assistant::RunnerCallbacksHelper
  include Captain::Assistant::AgentRunResponse
  include Captain::Assistant::RunnerInstrumentationHelper
  include Captain::Assistant::TracePayloadHelper
  include Captain::Assistant::RunnerStateHelper

  attr_reader :last_run_result

  def initialize(assistant:, conversation: nil, callbacks: {}, source: nil, responding_to_message_id: nil)
    # The agents runner builds RubyLLM agents lazily, so the LLM provider config
    # (API key / endpoint) must be applied before the first run or RubyLLM raises
    # "Missing configuration for ..." and the agent returns an empty response.
    Llm::Config.initialize!
    @assistant = assistant
    @conversation = conversation
    @callbacks = callbacks
    @source = source
    @responding_to_message_id = responding_to_message_id
    @handoff_tool_called = false
    @handoff_tool_completed = false
    @handoff_offer_pending = false
    @simple_reply_handled = false
  end

  def generate_response(message_history: [])
    decision_trace_builder.reset!
    simple_reply = resolve_simple_reply(message_history)
    return simple_reply_response(simple_reply) if simple_reply

    message_to_process, context = run_payload(message_history)
    @last_run_result = runner.run(message_to_process, context: context, max_turns: 10)
    record_turn_start(@last_run_result)
    @last_run_result = rewrite_oversized_response(@last_run_result) if response_too_long?(@last_run_result)

    raise "Captain response exceeds the channel limit of #{message_length_limit} characters" if response_too_long?(@last_run_result)

    process_agent_result(@last_run_result)
  rescue StandardError => e
    # In rake/local runs, conversation may not be present, so account is optional here.
    ChatwootExceptionTracker.new(e, account: @conversation&.account).capture_exception
    Rails.logger.error "[Captain V2] AgentRunnerService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    error_response(e)
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

  # Ordered list of decision nodes for the most recent run (or empty for a
  # simple-reply answer, which bypasses the LLM runner entirely).
  def decision_trace
    @decision_trace_builder&.to_h || []
  end

  # True when the deterministic keyword layer answered instead of the LLM. Both
  # the conversation pipeline and the playground share this via the runner, so
  # simple replies are part of the base agent flow, not a side channel.
  def simple_reply_handled? = @simple_reply_handled == true

  private

  def resolve_simple_reply(message_history)
    customer_content = extract_last_user_message_text(message_history)
    return if customer_content.blank?

    @assistant.simple_replies.enabled.find { |reply| reply.matches?(customer_content) }
  end

  def extract_last_user_message_text(message_history)
    last_user_msg = message_history.reverse.find { |msg| msg[:role] == 'user' }
    return '' if last_user_msg.blank?

    content = last_user_msg[:content]
    return content.to_s unless content.is_a?(Array)

    text, = Captain::OpenAiMessageBuilderService.extract_text_and_attachments(content)
    text.to_s
  end

  def simple_reply_response(simple_reply)
    @simple_reply_handled = true
    {
      'response' => simple_reply.reply,
      'response_parts' => [{ 'text' => simple_reply.reply, 'citation_indexes' => [] }],
      'reasoning' => 'Simple reply matched',
      'simple_reply' => true
    }
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
