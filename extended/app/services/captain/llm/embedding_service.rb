require 'openai'

class Captain::Llm::EmbeddingService < Llm::BaseOpenAiService
  class EmbeddingsError < StandardError; end

  def self.embedding_model
    provider = InstallationConfig.find_by(name: 'CAPTAIN_LLM_PROVIDER')&.value
    defaults = LlmConstants.defaults_for(provider)
    @embedding_model = InstallationConfig.find_by(name: 'CAPTAIN_LLM_EMBEDDING_MODEL')&.value.presence || defaults[:embedding_model]
  end

  def get_embedding(content, model: self.class.embedding_model)
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
