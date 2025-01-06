require 'openai'

class Captain::Llm::EmbeddingService
  class EmbeddingsError < StandardError; end

  DEFAULT_MODEL = 'text-embedding-3-small'.freeze

  def initialize
    @client = OpenAI::Client.new(
      access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
      log_errors: Rails.env.development?
    )
  rescue StandardError => e
    raise EmbeddingsError, "Failed to initialize OpenAI client: #{e.message}"
  end

  def get_embedding(content, model: DEFAULT_MODEL)
    response = @client.embeddings(
      parameters: {
        model: model,
        input: content
      }
    )

    response.dig('data', 0, 'embedding')
  rescue StandardError => e
    raise EmbeddingsError, "Failed to create an embedding: #{e.message}"
  end
end
