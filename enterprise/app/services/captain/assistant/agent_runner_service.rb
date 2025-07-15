require 'agents'

class Captain::Assistant::AgentRunnerService
  CONVERSATION_STATE_ATTRIBUTES = %i[
    id display_id inbox_id contact_id status priority
    label_list custom_attributes additional_attributes
  ].freeze

  def initialize(assistant:, conversation: nil)
    @assistant = assistant
    @conversation = conversation
  end

  def generate_response(message_history: [])
    agents = build_and_wire_agents
    context = build_context(message_history)
    message_to_process = extract_last_user_message(message_history)
    runner = Agents::Runner.with_agents(*agents)
    result = runner.run(message_to_process, context: context)

    process_agent_result(result)
  rescue StandardError => e
    Rails.logger.error "[Captain V2] AgentRunnerService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    error_response(e.message)
  end

  private

  def build_context(message_history)
    conversation_history = message_history.map do |msg|
      content = extract_text_from_content(msg[:content])

      {
        role: msg[:role].to_sym,
        content: content,
        agent_name: msg[:agent_name]
      }
    end

    {
      conversation_history: conversation_history,
      state: build_state
    }
  end

  def extract_last_user_message(message_history)
    last_user_msg = message_history.reverse.find { |msg| msg[:role] == 'user' }

    extract_text_from_content(last_user_msg[:content])
  end

  def extract_text_from_content(content)
    return content unless content.is_a?(Array)

    text_parts = content.select { |part| part[:type] == 'text' }.pluck(:text)
    text_parts.join(' ')
  end

  # Response formatting methods
  def process_agent_result(result)
    Rails.logger.info "[Captain V2] Agent result: #{result.inspect}"
    format_response(result.output)
  end

  def format_response(output)
    parsed = parse_json_output(output)

    if parsed.is_a?(Hash)
      {
        'response' => parsed['response'] || parsed['result'] || output.to_s,
        'reasoning' => parsed['reasoning'] || parsed['thought_process'] || 'Processed by agent'
      }
    else
      {
        'response' => output.to_s,
        'reasoning' => 'Processed by agent'
      }
    end
  end

  def error_response(error_message)
    {
      'response' => 'conversation_handoff',
      'reasoning' => "Error occurred: #{error_message}"
    }
  end

  def parse_json_output(output)
    return output if output.is_a?(Hash)
    return nil unless output.is_a?(String)

    JSON.parse(output)
  rescue JSON::ParserError
    nil
  end

  def build_state
    state = {
      account_id: @assistant.account_id,
      assistant_id: @assistant.id,
      assistant_config: @assistant.config
    }

    state[:conversation] = @conversation.attributes.symbolize_keys.slice(*CONVERSATION_STATE_ATTRIBUTES) if @conversation

    state
  end

  def build_and_wire_agents
    assistant_agent = @assistant.agent
    scenario_agents = @assistant.scenarios.enabled.map { |scenario| scenario.agent }

    assistant_agent.register_handoffs(*scenario_agents) if scenario_agents.any?
    scenario_agents.each { |scenario_agent| scenario_agent.register_handoffs(assistant_agent) }

    [assistant_agent] + scenario_agents
  end
end
