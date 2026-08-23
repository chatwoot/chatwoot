class Captain::Llm::EmbeddingService
  include Integrations::LlmInstrumentation

  class EmbeddingsError < StandardError; end

  def initialize(account_id: nil)
    Llm::Config.initialize!
    @account_id = account_id
    @embedding_model = self.class.embedding_model
  end

  def self.embedding_model
    Llm::Config.embedding_model
  end

  def get_embedding(content, model: @embedding_model)
    return [] if content.blank?

    vectors = instrument_embedding_call(instrumentation_params(content, model)) do
      RubyLLM.embed(
        content,
        model: model,
        provider: embedding_provider(model),
        assume_model_exists: true
      ).vectors
    end

    validate_dimension!(vectors, model)
    vectors
  rescue EmbeddingsError
    raise
  rescue StandardError => e
    Rails.logger.error "Embedding API Error: #{e.message}"
    log_failure(e, model)
    raise EmbeddingsError, "Failed to create an embedding: #{e.message}"
  end

  # pgvector columns are fixed at LlmConstants::EMBEDDING_DIMENSION. If the
  # configured embedding model emits a different number of dimensions, writing
  # the vector fails with an opaque DB error. Detect that up front so the failure
  # is reported clearly (and persisted) instead of surfacing as a raw SQL error.
  def validate_dimension!(vectors, model)
    return unless vectors.size != LlmConstants::EMBEDDING_DIMENSION

    error = EmbeddingsError.new(
      "Embedding model '#{model}' returned #{vectors.size} dimensions, " \
      "expected #{LlmConstants::EMBEDDING_DIMENSION}."
    )
    log_failure(error, model)
    raise error
  end

  def log_failure(error, model)
    Captain::Llm::FailureLogger.record(
      source: :embedding,
      error: error,
      model: model,
      account_id: @account_id
    )
  end

  private

  # The embedding model may be a custom model id (e.g. an OpenRouter model with a
  # `provider/name:free` format) that RubyLLM has no registry entry for. Declaring
  # the provider explicitly and assuming the model exists lets us use any model the
  # configured endpoint supports instead of failing on unknown model ids.
  def embedding_provider(model)
    Llm::Config.provider_for(model) || provider_from_endpoint || :openai
  end

  def provider_from_endpoint
    endpoint = Llm::Config.openai_endpoint
    return :openrouter if endpoint&.include?('openrouter.ai')

    nil
  end

  def instrumentation_params(content, model)
    {
      span_name: 'llm.captain.embedding',
      model: model,
      input: content,
      feature_name: 'embedding',
      account_id: @account_id
    }
  end
end
