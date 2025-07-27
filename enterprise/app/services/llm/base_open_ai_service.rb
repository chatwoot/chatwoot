class Llm::BaseOpenAiService
  DEFAULT_MODEL = '@cf/meta/llama-3.3-70b-instruct-fp8-fast'.freeze

  def initialize
    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
      log_errors: Rails.env.development?
    )
    setup_model
  rescue StandardError => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end

  private

  def setup_model
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (config_value.presence || DEFAULT_MODEL)
  end
end
