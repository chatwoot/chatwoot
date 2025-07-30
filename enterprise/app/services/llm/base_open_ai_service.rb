class Llm::BaseOpenAiService
  DEFAULT_MODEL = '@cf/meta/llama-3.3-70b-instruct-fp8-fast'.freeze

  def initialize
    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
      uri_base: uri_base,
      log_errors: Rails.env.development?
    )
    setup_model
  rescue StandardError => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end

  private

  def uri_base
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value || 'https://api.cloudflare.com/client/v4/accounts/e365f68be929a7213c1350bbb51a4cd3/ai/'
  end

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (config_value.presence || DEFAULT_MODEL)
  end
end
