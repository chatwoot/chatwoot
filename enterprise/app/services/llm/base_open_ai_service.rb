class Llm::BaseOpenAiService
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze

  # Captain logging event types
  REQUEST = 'REQUEST'.freeze
  RESPONSE = 'RESPONSE'.freeze
  TOOL_CALL = 'TOOL_CALL'.freeze
  ERROR = 'ERROR'.freeze

  def initialize
    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
      uri_base: uri_base,
      log_errors: Rails.env.development?
    )
    setup_model
    @enhanced_logging_enabled = ENV['CAPTAIN_ENHANCED_LOGGING'].present?
  rescue StandardError => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end

  private

  def uri_base
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value || 'https://api.openai.com/'
  end

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (config_value.presence || DEFAULT_MODEL)
  end

  def log_captain_activity(event_type, log_data = {})
    return unless @enhanced_logging_enabled

    conversation_id = log_data[:conversation_id]
    prefix = conversation_id ? "[##{conversation_id}]" : ''

    # Add timestamp to all log data
    log_data[:timestamp] = Time.current.iso8601

    Rails.logger.info "[CAPTAIN_DEBUG] #{prefix} [#{event_type}] #{JSON.pretty_generate(log_data)}"
  end
end
