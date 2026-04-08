class Captain::Llm::EmbeddingService
  include Integrations::LlmInstrumentation

  class EmbeddingsError < StandardError; end

  def initialize(account_id: nil)
    Llm::Config.initialize!
    @account_id = account_id
    @embedding_model = InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_MODEL')&.value.presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
    @embedding_dimensions = configured_embedding_dimensions
    @ruby_llm_provider = LlmConstants.captain_ruby_llm_provider
  end

  def self.embedding_model
    InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_MODEL')&.value.presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
  end

  def get_embedding(content, model: @embedding_model)
    return [] if content.blank?

    instrument_embedding_call(instrumentation_params(content, model)) do
      # Local model IDs may be absent from RubyLLM's catalog; pass Captain's configured provider.
      # `dimensions` matches pgvector / Neighbor column width (see LlmConstants::EMBEDDING_VECTOR_DIMENSIONS).
      raw = RubyLLM.embed(
        content,
        model: model,
        provider: @ruby_llm_provider,
        dimensions: @embedding_dimensions
      ).vectors
      coerce_embedding_length(raw)
    end
  rescue RubyLLM::Error => e
    Rails.logger.error "Embedding API Error: #{e.message}"
    raise EmbeddingsError, "Failed to create an embedding: #{e.message}"
  end

  private

  def configured_embedding_dimensions
    raw = InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_DIMENSIONS')&.value
    parsed = raw.to_s.strip.to_i
    return parsed if parsed.positive?

    LlmConstants::EMBEDDING_VECTOR_DIMENSIONS
  end

  # Ollama should honor `dimensions` on /v1/embeddings; truncate if an older server still returns full width.
  def coerce_embedding_length(vectors)
    return vectors if vectors.blank?

    target = @embedding_dimensions
    case vectors.length
    when target
      vectors
    when ->(n) { n > target }
      Rails.logger.warn(
        "Captain embedding length #{vectors.length} truncated to #{target} (Neighbor/pgvector schema)"
      )
      vectors.take(target)
    else
      raise EmbeddingsError,
            "Embedding API returned #{vectors.length} dimensions; expected #{target}"
    end
  end

  def instrumentation_params(content, model)
    {
      span_name: 'llm.captain.embedding',
      model: model,
      dimensions: @embedding_dimensions,
      input: content,
      feature_name: 'embedding',
      account_id: @account_id
    }
  end
end
