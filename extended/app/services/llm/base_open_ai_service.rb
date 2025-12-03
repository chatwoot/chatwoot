class Llm::BaseOpenAiService
  attr_reader :client, :model

  def initialize
    defaults = LlmConstants.current_defaults
    raise 'LLM provider not configured. Please set CAPTAIN_LLM_PROVIDER in InstallationConfig.' if defaults.nil?

    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_LLM_API_KEY').value,
      uri_base: uri_base,
      log_errors: Rails.env.development?
    )
    setup_model
  rescue ActiveRecord::RecordNotFound => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end

  private

  def uri_base
    defaults = LlmConstants.current_defaults
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_LLM_ENDPOINT')&.value
    endpoint.presence || (defaults&.[](:endpoint) || 'https://api.openai.com/')
  end

  def setup_model
    defaults = LlmConstants.current_defaults
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_LLM_MODEL')&.value
    @model = (config_value.presence || defaults[:chat_model])
  end
end
