class Captain::Llm::BaseOpenAiService
  def initialize
    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
      log_errors: Rails.env.development?
    )
  rescue StandardError => e
    raise EmbeddingsError, "Failed to initialize OpenAI client: #{e.message}"
  end
end
