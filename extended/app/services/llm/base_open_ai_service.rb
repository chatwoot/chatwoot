class Llm::BaseOpenAiService
  attr_reader :client, :model

  def initialize
    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_LLM_API_KEY').value,
      uri_base: uri_base,
      log_errors: Rails.env.development?
    )
    setup_model
  rescue StandardError => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end

  private

  def uri_base
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_LLM_ENDPOINT')&.value
    endpoint.presence || 'https://api.openai.com/'
  end

  def setup_model
    provider = InstallationConfig.find_by(name: 'CAPTAIN_LLM_PROVIDER')&.value
    defaults = LlmConstants.defaults_for(provider)
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_LLM_MODEL')&.value
    @model = (config_value.presence || defaults[:chat_model])
  end
end
