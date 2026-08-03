require 'agents'
require 'agents/instrumentation'

class Captain::Assistant::AgentRunnerService
  include Captain::Assistant::RunnerCallbacksHelper
  include Captain::Assistant::RunnerInstrumentationHelper
  include Captain::Assistant::TracePayloadHelper
  include Captain::Assistant::RunnerStateHelper

  attr_reader :last_run_result

  def initialize(assistant:, conversation: nil, callbacks: {}, source: nil, responding_to_message_id: nil)
    @assistant = assistant
    @conversation = conversation
    @callbacks = callbacks
    @source = source
    @responding_to_message_id = responding_to_message_id
    @handoff_tool_called = false
    @handoff_tool_completed = false
  end

  def generate_response(message_history: [])
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

  private

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
    return content[:response] || content['response'] || content.to_s if content.is_a?(Hash)

    return content unless content.is_a?(Array)

    text_parts = content.select { |part| part[:type] == 'text' }.pluck(:text)
    text_parts.join(' ')
  end

  def process_agent_result(result)
    Rails.logger.info "[Captain V2] Agent result: #{result.inspect}"
    output = result.output
    response = output.is_a?(Hash) ? output.with_indifferent_access : { 'response' => output.to_s, 'reasoning' => 'Processed by agent' }
    response['agent_name'] = result.context&.dig(:current_agent)
    response['handoff_tool_called'] = result.context&.dig(:captain_v2_handoff_tool_called) || false
    response
  end

  def rewrite_oversized_response(result)
    response_rewriter.rewrite(result, response: response_text(result), limit: message_length_limit)
  end

  def response_rewriter
    @response_rewriter ||= Captain::Assistant::ResponseRewriter.new(
      assistant: @assistant,
      attribute_provider: Captain::Assistant::InstrumentationAttributeProvider.new(self)
    )
  end

  def record_turn_start(result)
    history = Array(result.context&.dig(:conversation_history))
    turn_start_index = history.rindex { |message| message[:role].to_s == 'user' }
    result.context[:captain_v2_turn_start_index] = turn_start_index if turn_start_index
  end

  def response_too_long?(result)
    message_length_limit && response_text(result).length > message_length_limit
  end

  def response_text(result)
    extract_text_from_content(result.output).to_s
  end

  def message_length_limit
    @message_length_limit ||= Captain::MessageLengthLimit.for(@conversation)
  end

  def error_response(error)
    {
      'response' => 'conversation_handoff',
      'reasoning' => "Error occurred: #{error.message}",
      'error' => true,
      'error_reason' => error.class.name.underscore.tr('/', '_'),
      'handoff_tool_called' => @handoff_tool_called
    }
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
      install_instrumentation(configured_runner)
      configured_runner
    end
  end

  def run_payload(message_history)
    message_to_process = extract_last_user_message(message_history)
    context = build_context(message_history_without_last_user_message(message_history))
    enrich_context_with_trace_payload!(context, message_history, message_to_process)
    [message_to_process, context]
  end
end
