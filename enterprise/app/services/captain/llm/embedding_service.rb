require 'openai'

class Captain::Llm::EmbeddingService < Llm::BaseOpenAiService
  class EmbeddingsError < StandardError; end

  DEFAULT_MODEL = 'text-embedding-3-small'.freeze
  EMBEDDING_MODEL = InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_MODEL')&.value.presence || DEFAULT_MODEL

  def get_embedding(content, model: EMBEDDING_MODEL)
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
