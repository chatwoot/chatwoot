require 'openai'

class Captain::Llm::EmbeddingService < Llm::BaseOpenAiService
  class EmbeddingsError < StandardError; end

  DEFAULT_MODEL = 'text-embedding-3-small'.freeze

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
