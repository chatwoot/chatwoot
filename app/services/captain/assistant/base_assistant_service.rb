require 'agents'

class Captain::Assistant::BaseAssistantService
  def initialize(text:)
    @text = text
  end

  def execute
    agent = build_agent
    runner = Agents::Runner.with_agents(agent)

    result = runner.run(@text, context: {})

    return error_response(result.error) if result.respond_to?(:error) && result.error

    process_result(result)
  rescue StandardError => e
    Rails.logger.error "[Captain V2] #{self.class.name} error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    error_response(e.message)
  end

  protected

  def build_agent
    Agents::Agent.new(
      name: agent_name,
      instructions: build_instructions,
      model: agent_model,
      response_schema: response_schema
    )
  end

  def agent_model
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || OpenAiConstants::DEFAULT_MODEL
  end

  def agent_name
    raise NotImplementedError, "#{self.class} must implement agent_name"
  end

  def build_instructions
    raise NotImplementedError, "#{self.class} must implement build_instructions"
  end

  def response_schema
    raise NotImplementedError, "#{self.class} must implement response_schema"
  end

  def process_result(result)
    output = result.output

    return error_response(output[:error] || output['error']) if output.is_a?(Hash) && (output[:error] || output['error'])

    build_success_response(output)
  end

  def build_success_response(output)
    {
      success: true,
      result: extract_primary_field(output),
      original_text: @text
    }
  end

  def error_response(error_message)
    {
      success: false,
      error: error_message,
      original_text: @text
    }
  end

  def extract_field(output, *field_names)
    return output.to_s unless output.is_a?(Hash)

    field_names.each do |field|
      value = output[field.to_sym] || output[field.to_s]
      return value if value
    end

    nil
  end

  def extract_primary_field(output)
    output
  end
end
