class Captain::Llm::BaseOpenAiService
  DEFAULT_MODEL = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value || 'gpt-4o-mini'

  def initialize
    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
      log_errors: Rails.env.development?
    )
  rescue StandardError => e
    raise "Failed to initialize OpenAI client: #{e.message}"
  end
end
