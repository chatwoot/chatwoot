require 'agents'
require 'agents/instrumentation'

class Captain::Assistant::AgentRunnerService
  include Captain::Assistant::RunnerCallbacksHelper
  include Captain::Assistant::AgentRunResponse
  include Captain::Assistant::RunnerInstrumentationHelper
  include Captain::Assistant::TracePayloadHelper
  include Captain::Assistant::RunnerStateHelper

  attr_reader :last_run_result

  REPLY_SUGGESTION_SOURCE = 'copilot_reply_suggestion'.freeze

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
    if content.is_a?(Hash)
      response_text = Captain::Assistant::ResponseParts.from_response(content).plain_text
      return response_text.presence || content.to_s
    end

    return content unless content.is_a?(Array)

    text_parts = content.select { |part| part[:type] == 'text' }.pluck(:text)
    text_parts.join(' ')
  end

  def build_and_wire_agents
    return [reply_suggestion_agent] if reply_suggestion?

    assistant_agent = @assistant.agent
    scenario_agents = @assistant.scenarios.enabled.map(&:agent)

    assistant_agent.register_handoffs(*scenario_agents) if scenario_agents.any?
    scenario_agents.each { |scenario_agent| scenario_agent.register_handoffs(assistant_agent) }

    [assistant_agent] + scenario_agents
  end

  def reply_suggestion_agent
    agent = @assistant.agent
    agent.clone(
      instructions: ->(context) { @assistant.agent_instructions(context, prompt_template: 'copilot_reply_suggestion') },
      tools: agent.tools.select { |tool| available_in_reply_suggestion?(tool) }
    )
  end

  def available_in_reply_suggestion?(tool)
    return true if tool.is_a?(Captain::Tools::FaqLookupTool)

    tool.is_a?(Captain::Tools::HttpTool) && tool.available_in_reply_suggestion?
  end

  def reply_suggestion? = @source == REPLY_SUGGESTION_SOURCE

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
