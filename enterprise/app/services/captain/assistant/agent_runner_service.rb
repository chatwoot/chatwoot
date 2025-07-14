require 'agents'

class Captain::Assistant::AgentRunnerService
  def initialize(assistant:, user: nil)
    @assistant = assistant
    @user = user
  end

  def generate_response(additional_message: nil, message_history: [], role: 'user')
    # Create the assistant agent with scenario handoffs
    agent = @assistant.agent(@user)

    # Convert message history to proper format for ai-agents
    formatted_history = format_message_history(message_history)

    # Build context with conversation history
    context = build_context(formatted_history)

    # Create agent runner
    runner = Agents::AgentRunner.new(agent: agent)

    # Add context if available
    runner.add_context(context) if context.present?

    # Get the message to process
    message_to_process = build_message_to_process(additional_message, message_history, role)

    # Run the agent
    result = runner.run(message_to_process)

    # Process and format the result
    process_agent_result(result)
  rescue StandardError => e
    Rails.logger.error "[Captain V2] AgentRunnerService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Return error response in expected format
    {
      'response' => 'conversation_handoff',
      'reasoning' => "Error occurred: #{e.message}"
    }
  end

  private

  def format_message_history(message_history)
    # Convert OpenAI format to a more readable format for context
    message_history.map do |msg|
      content = msg[:content]
      # Handle multimodal content
      if content.is_a?(Array)
        text_parts = content.select { |part| part[:type] == 'text' }.pluck(:text)
        content = text_parts.join(' ')
      end

      "#{msg[:role]}: #{content}"
    end.join("\n")
  end

  def build_context(formatted_history)
    {
      conversation_history: formatted_history,
      account_id: @assistant.account_id,
      user_id: @user&.id,
      assistant_id: @assistant.id,
      assistant_config: @assistant.config,
      timestamp: Time.current.to_i
    }
  end

  def build_message_to_process(additional_message, message_history, _role)
    return additional_message if additional_message.present?

    extract_last_user_message(message_history)
  end

  def extract_last_user_message(message_history)
    last_user_msg = message_history.reverse.find { |msg| msg[:role] == 'user' }
    return '' unless last_user_msg

    extract_text_from_content(last_user_msg[:content])
  end

  def extract_text_from_content(content)
    return content unless content.is_a?(Array)

    text_parts = content.select { |part| part[:type] == 'text' }.pluck(:text)
    text_parts.join(' ')
  end

  def process_agent_result(result)
    # Log the result for debugging
    Rails.logger.info "[Captain V2] Agent result: #{result.inspect}"

    # Check if there was a handoff to a scenario
    Rails.logger.info "[Captain V2] Handoff to scenario: #{result.pending_handoff[:agent_name]}" if result.pending_handoff.present?

    # Format the response to match expected structure
    format_response(result.output, result)
  end

  def format_response(output, result)
    response_hash = parse_output_to_hash(output, result)

    {
      'response' => extract_response_content(response_hash, output),
      'reasoning' => extract_reasoning(response_hash, result)
    }
  end

  def parse_output_to_hash(output, _result)
    return output if output.is_a?(Hash)
    return {} unless output.is_a?(String) && output.include?('{')

    JSON.parse(output)
  rescue JSON::ParserError
    {}
  end

  def extract_response_content(parsed_hash, original_output)
    return original_output.to_s if parsed_hash.empty?

    parsed_hash['response'] || parsed_hash['result'] || original_output.to_s
  end

  def extract_reasoning(parsed_hash, result)
    return "Processed by #{result.agent_name}" if parsed_hash.empty?

    parsed_hash['reasoning'] || parsed_hash['thought_process'] || "Processed by #{result.agent_name}"
  end
end