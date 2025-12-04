require 'openai'

class Captain::Llm::EmbeddingService < Llm::BaseService
  class EmbeddingsError < StandardError; end

  def self.embedding_model
    Captain::Config.config_for(Captain::Config.current_provider)[:embedding_model]
  end

  def get_embedding(content, model: self.class.embedding_model)
    response = @provider.embeddings(
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
